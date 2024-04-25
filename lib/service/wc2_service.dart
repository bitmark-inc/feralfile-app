//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: avoid_annotating_with_dynamic

import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/model/wc_ethereum_transaction.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_sign_message_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_connect_ext.dart';
import 'package:autonomy_flutter/util/wc2_ext.dart';
import 'package:autonomy_flutter/util/wc2_tezos_ext.dart';
import 'package:collection/collection.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/credentials.dart';

class Wc2Service {
  static final Set<String> _supportedChains = {
    Wc2Chain.autonomy,
    Wc2Chain.ethereum,
    Wc2Chain.tezos,
  };

  static final Set<String> supportedMethods = {
    'au_sign',
    'au_permissions',
    'au_sendTransaction',
    'eth_sendTransaction',
    'personal_sign',
    'eth_sign',
    'eth_signTypedData',
    'eth_signTypedData_v4',
    'eth_signTransaction',
    'wallet_addEthereumChain',
  };

  static const PairingMetadata pairingMetadata = PairingMetadata(
    name: 'Feral File',
    description: 'Feral File Wallet',
    url: 'https://app.feralfile.com',
    icons: [],
  );

  static const unknownProposer = PairingMetadata(
    name: 'Unknown',
    description: 'Unknown',
    url: 'unknown',
    icons: [],
  );

  final NavigationService _navigationService;
  final AccountService _accountService;
  final CloudDatabase _cloudDB;

  late Web3Wallet _wcClient;
  String pendingUri = '';

  Timer? _timer;

  final List<String> _approvedConnectionKey = [];

  void addApprovedTopic(List<String> keys) {
    _approvedConnectionKey.addAll(keys);
  }

  bool isApprovedTopic(String topic) =>
      _approvedConnectionKey.any((element) => element.contains(topic));

  Wc2Service(
    this._navigationService,
    this._accountService,
    this._cloudDB,
  ) {
    unawaited(init());
  }

  static const WalletConnectError _userRejectError =
      WalletConnectError(code: 5000, message: 'User rejected');
  static const WalletConnectError _proposalNotFound =
      WalletConnectError(code: 6000, message: 'App can not found proposal');
  static const WalletConnectError _chainNotSupported =
      WalletConnectError(code: 3005, message: 'Chain is not supported');

  Future<void> init() async {
    _wcClient = await Web3Wallet.createInstance(
      projectId: '33abc0fd433c7a6e1cc198273e4a7d6e',
      metadata: pairingMetadata,
    );
    _wcClient.onSessionProposal.subscribe(_onSessionProposal);
    _wcClient.onSessionRequest.subscribe((request) {
      log.info('[Wc2Service] Finish handle request $request');
    });

    _registerEthRequest('${Wc2Chain.ethereum}:${Environment.web3ChainId}');
    _registerEthRequest('${Wc2Chain.ethereum}:5');

    _registerFeralfileRequest(
        '${Wc2Chain.autonomy}:${Environment.appTestnetConfig ? 1 : 0}');
    addApprovedTopic(await _getAllConnectionKey());
  }

  void _registerEthRequest(String chainId) {
    final Map<String, dynamic Function(String, dynamic)?> ethRequestHandlerMap =
        {
      'eth_sendTransaction': _handleEthSendTx,
      'personal_sign': (String topic, params) async =>
          _wait4SessionApproveThenHandleRequest(
              topic, params, _handleEthPersonalSign),
      'eth_sign': _handleEthSign,
      'eth_signTypedData': _handleEthSignType,
      'eth_signTypedData_v4': _handleEthSignType,
    };
    log.info('[Wc2Service] Registering handlers for chainId: $chainId');
    ethRequestHandlerMap.forEach((method, handler) {
      _wcClient.registerRequestHandler(
          chainId: chainId,
          method: method,
          handler: (String topic, params) async =>
              _checkResultWrapper(topic, params, handler));
    });
  }

  void _registerFeralfileRequest(String chainId) {
    final Map<String, dynamic Function(String, dynamic)?>
        feralfileRequestHandlerMap = {
      'au_sign': _handleAuSign,
      'au_permissions': (String topic, params) async =>
          _wait4SessionApproveThenHandleRequest(
              topic, params, _handleAuPermissions),
      'au_sendTransaction': _handleAuSendTx,
    };
    log.info('[Wc2Service] Registering handlers for chainId: $chainId');
    feralfileRequestHandlerMap.forEach(
      (method, handler) {
        _wcClient.registerRequestHandler(
            chainId: chainId,
            method: method,
            handler: (String topic, params) async =>
                _checkResultWrapper(topic, params, handler));
      },
    );
  }

  Future<void> _wait4SessionApproveThenHandleRequest(
      String topic, params, dynamic Function(String, dynamic) handler) async {
    int counter = 0;
    const maxCounter = 20;
    do {
      counter++;
      log.info('[Wc2Service] waiting for user to approve');
      await Future.delayed(const Duration(milliseconds: 500));
    } while (!isApprovedTopic(topic) || counter > maxCounter);
    return await handler(topic, params);
  }

  Future<dynamic> _checkResultWrapper(
      String topic, params, dynamic Function(String, dynamic)? handler) async {
    if (handler == null) {
      return;
    }
    final result = await handler(topic, params);
    if (result == null || result == false) {
      throw _userRejectError;
    }
    return result;
  }

  Future _handleAuPermissions(String topic, params) async {
    log.info('[Wc2Service] received autonomy-au_permissions request $params');
    final proposer = await _getWc2Request(topic, params);
    if (proposer == null) {
      throw _proposalNotFound;
    }
    return await _navigationService.navigateTo(
      AppRouter.wc2PermissionPage,
      arguments:
          Wc2RequestPayload(params: params, topic: topic, proposer: proposer),
    );
  }

  Future _handleAuSign(String topic, params) async {
    log.info('[Wc2Service] received autonomy-au_sign request $params');
    final chain = (params['chain'] as String).caip2Namespace;
    switch (chain) {
      case Wc2Chain.ethereum:
        return await _handleAuSignEth(topic, params);
      case Wc2Chain.tezos:
        return await _handleTezosSignRequest(topic, params);
      case Wc2Chain.autonomy:
        log.info('[Wc2Service] received autonomy-au_sign request $params');
        return await _handleFeralfileSign(topic, params);
      default:
        log.warning('[Wc2Service] Chain not supported: $chain');
        throw _chainNotSupported;
    }
  }

  Future _handleEthPersonalSign(String topic, params) async {
    log.info('[Wc2Service] received eip155-eth_sign request $params');
    return await _ethSign(topic, params, WCSignType.PERSONAL_MESSAGE);
  }

  Future _handleEthSign(String topic, params) async {
    log.info('[Wc2Service] received eip155-eth_sign request $params');
    return await _ethSign(topic, params, WCSignType.MESSAGE);
  }

  Future _handleEthSignType(String topic, params) async {
    log.info('[Wc2Service] received eip155-eth_sign request $params');
    return await _ethSign(topic, params, WCSignType.TYPED_MESSAGE);
  }

  Future _ethSign(String topic, params, WCSignType wcSignType) async {
    final proposer = await _getWc2Request(topic, params);
    if (proposer == null) {
      throw _proposalNotFound;
    }
    return await _handleWC2EthereumSignRequest(
        params, topic, proposer, wcSignType);
  }

  Future _handleEthSendTx(String topic, params) async {
    log.info('[Wc2Service] received eip155-eth_sendTx request $params');
    final proposer = await _getWc2Request(topic, params);
    if (proposer == null) {
      throw _proposalNotFound;
    }
    return await _handleEthSendTransactionRequest(params, proposer, topic);
  }

  Future _handleAuSignEth(String topic, params) async {
    log.info('[Wc2Service] received eip155-au_sign request $params');
    final proposer = await _getWc2Request(topic, params);
    if (proposer == null) {
      throw _proposalNotFound;
    }
    final result = await _handleWC2EthereumSignRequest(
        params, topic, proposer, WCSignType.PERSONAL_MESSAGE);
    return result;
  }

  Future _handleFeralfileSign(String topic, parmas) async {
    final proposer = await _getWc2Request(topic, parmas);
    if (proposer == null) {
      throw _proposalNotFound;
    }
    return await _handleAutonomySignRequest(parmas, topic, proposer);
  }

  Future _handleAuSendTx(String topic, params) async {
    log.info('[Wc2Service] received au_sendTransaction request $params');
    final proposer = await _getWc2Request(topic, params);
    if (proposer == null) {
      throw _proposalNotFound;
    }
    final chain = (params['chain'] as String).caip2Namespace;
    switch (chain) {
      case Wc2Chain.ethereum:
        return await _handleAuEthSendTransactionRequest(
            params, proposer, topic);
      case Wc2Chain.tezos:
        return await _handleAuTezSendTransactionRequest(
            params, proposer, topic);
      default:
        log.warning('[Wc2Service] Chain not supported: $chain');
        throw _chainNotSupported;
    }
  }

  Future<PairingMetadata?> _getWc2Request(String topic, params) async {
    final connections = await _cloudDB.connectionDao.getWc2Connections();
    final connection =
        connections.firstWhereOrNull((element) => element.key.contains(topic));
    if (connection != null) {
      final proposer = PairingMetadata.fromJson(jsonDecode(connection.data));
      return proposer;
    }
    final pairingMetadata = _wcClient.sessions
        .getAll()
        .where((element) => element.topic == topic)
        .firstOrNull
        ?.peer
        .metadata;

    if (pairingMetadata != null) {
      return pairingMetadata;
    }

    log.warning('[Wc2Service] proposer not found for $topic');
    return null;
  }

  Future<List<String>> _getAllConnectionKey() async {
    final connections = await _cloudDB.connectionDao.getWc2Connections();
    return connections.map((e) => e.key).toList();
  }

  List<SessionRequest> getPendingRequests() =>
      _wcClient.pendingRequests.getAll();

  Future connect(String uri, {Function? onTimeout}) async {
    if (uri.isAutonomyConnectUri) {
      pendingUri = uri;
      _timer?.cancel();
      _timer = Timer(CONNECT_FAILED_DURATION, () {
        onTimeout?.call();
      });
      await _wcClient.pair(uri: Uri.parse(uri));
    }
  }

  Future cleanup() async {
    final connections = await _cloudDB.connectionDao
        .getConnectionsByType(ConnectionType.walletConnect2.rawValue);

    // retains connections under 7 days old and limit to 5 connections.
    while (connections.length > 5 &&
        connections.last.createdAt
            .isBefore(DateTime.now().subtract(const Duration(days: 7)))) {
      connections.removeLast();
    }
    /*
    final ids = connections
        .map((e) => e.key.split(":").lastOrNull)
        .whereNotNull()
        .toList();

    _wcClient.cleanup(ids);

     */
  }

  Future approveSession(Wc2Proposal proposal,
      {required List<String> accounts,
      required String connectionKey,
      required String accountNumber,
      bool isAuConnect = false}) async {
    final Map<String, RequiredNamespace> mergedNamespaces =
        _mergeRequiredNameSpaces(
      proposal.requiredNamespaces,
      proposal.optionalNamespaces,
    );
    final Map<String, Namespace> namespaces = {};
    mergedNamespaces.forEach((key, value) {
      namespaces[key] = value.toNameSpace(accounts);
    });
    final resF = _wcClient.approveSession(
      id: proposal.id,
      namespaces: namespaces,
    );
    final res = await resF;
    final topic = res.topic;
    log.info('[Wc2Service] approveSession topic $topic');

    final connection = Connection(
      key: '$connectionKey:$topic',
      name: proposal.proposer.name,
      data: json.encode(proposal.proposer),
      connectionType: isAuConnect
          ? ConnectionType.walletConnect2.rawValue
          : ConnectionType.dappConnect2.rawValue,
      accountNumber: accountNumber,
      createdAt: DateTime.now(),
    );
    await _cloudDB.connectionDao.insertConnection(connection);
    return res;
  }

  Future rejectSession(
    int id, {
    String? reason,
  }) async {
    log.info('[Wc2Service] reject session');
    await _wcClient.rejectSession(id: id, reason: _userRejectError);
  }

  Map<String, RequiredNamespace> _mergeRequiredNameSpaces(
      Map<String, RequiredNamespace> a, Map<String, RequiredNamespace> b) {
    Map<String, RequiredNamespace> merged = {};

    // Merge maps from a
    a.forEach((key, value) {
      if (b.containsKey(key)) {
        // Merge lists if key exists in both maps
        merged[key] = RequiredNamespace(
          chains: {...?b[key]?.chains, ...?value.chains}.toList(),
          methods: {...?b[key]?.methods, ...value.methods}.toList(),
          events: {...?b[key]?.events, ...value.events}.toList(),
        );
      } else {
        // Add entry from a if it doesn't exist in b
        merged[key] = value;
      }
    });

    // Merge remaining entries from b
    b.forEach((key, value) {
      if (!merged.containsKey(key)) {
        // Add entry from b if it doesn't exist in a
        merged[key] = value;
      }
    });

    return merged;
  }

  //#region Pairing

  Future deletePairing({required String topic}) async {
    log.info('[Wc2Service] Delete pairing. Topic: $topic');
    await _wcClient.disconnectSession(
        topic: topic, reason: Errors.getSdkError(Errors.USER_DISCONNECTED));
  }

  //#endregion

  //#region Events handling

  Future<void> _onSessionProposal(SessionProposalEvent? proposal) async {
    if (proposal == null) {
      return;
    }
    log
      ..info('[WC2Service] onSessionProposal: id = ${proposal.id}')
      ..info('[WC2Service] onSessionProposal: topic = '
          '${proposal.params.pairingTopic}')
      ..info(
        '[WC2Service] onSessionProposal: sessionProperties = '
        '${proposal.params.sessionProperties}',
      );
    _timer?.cancel();
    final unsupportedChains = proposal.params.requiredNamespaces.keys
        .toSet()
        .difference(_supportedChains);
    if (unsupportedChains.isNotEmpty) {
      log.info('[Wc2Service] Proposal contains unsupported chains: '
          '$unsupportedChains');
      await rejectSession(
        proposal.id,
        reason: "Chains ${unsupportedChains.join(", ")} not supported",
      );
      return;
    }

    final proposalMethods = proposal.params.requiredNamespaces.values
        .map((e) => e.methods)
        .flattened
        .toSet();
    final unsupportedMethods = proposalMethods.difference(supportedMethods);
    if (unsupportedMethods.isNotEmpty) {
      log.info('[Wc2Service] Proposal contains unsupported methods: '
          '$unsupportedMethods');
    }
    final wc2Proposal = Wc2Proposal(proposal.id,
        proposer: proposal.params.proposer.metadata,
        requiredNamespaces: proposal.params.requiredNamespaces,
        optionalNamespaces: proposal.params.optionalNamespaces);
    unawaited(_navigationService.navigateTo(AppRouter.wc2ConnectPage,
        arguments: wc2Proposal));
  }

  //#endregion
  Future _handleWC2EthereumSignRequest(params, String topic,
      PairingMetadata proposer, WCSignType signType) async {
    String address;
    String message;
    if (signType == WCSignType.PERSONAL_MESSAGE) {
      address = params[1];
      message = params[0];
    } else {
      address = params[0];
      if (params[1].runtimeType != String) {
        message = jsonEncode(params[1]);
      } else {
        message = params[1];
      }
    }

    final eip55address = EthereumAddress.fromHex(address).hexEip55;
    final wallet = await _accountService.getAccountByAddress(
      chain: 'eip155',
      address: eip55address,
    );
    final result =
        await _navigationService.navigateTo(AppRouter.wcSignMessagePage,
            arguments: WCSignMessagePageArgs(
              topic,
              proposer,
              message,
              signType,
              wallet.wallet.uuid,
              wallet.index,
            ));
    if (result is bool && !result) {
      throw _userRejectError;
    } else {
      return result;
    }
  }

  Future _handleEthSendTransactionRequest(
      params, PairingMetadata proposer, String topic) async {
    try {
      var transaction = params[0] as Map<String, dynamic>;
      final eip55address =
          EthereumAddress.fromHex(transaction['from']).hexEip55;
      final walletIndex = await _accountService.getAccountByAddress(
        chain: 'eip155',
        address: eip55address,
      );
      if (transaction['data'] == null) {
        transaction['data'] = '';
      }
      if (transaction['gas'] == null) {
        transaction['gas'] = '';
      }
      if (transaction['to'] == null) {
        log.info('[Wc2Service] Invalid transaction: no recipient');
        throw JsonRpcError.invalidParams('Invalid transaction: no recipient');
      }
      final args = WCSendTransactionPageArgs(
        proposer,
        WCEthereumTransaction.fromJson(transaction),
        walletIndex.wallet.uuid,
        walletIndex.index,
        topic: topic,
      );
      return await _navigationService.navigateTo(
        AppRouter.wcSendTransactionPage,
        arguments: args,
      );
    } catch (e) {
      throw JsonRpcError.invalidParams(e.toString());
    }
  }

  Future _handleTezosSignRequest(String topic, param) async {
    final proposer = await _getWc2Request(topic, param);
    if (proposer == null) {
      throw _proposalNotFound;
    }
    final beaconRequest = getBeaconRequest(
      topic,
      param,
      proposer,
      0,
    );
    return await _navigationService.navigateTo(
      AppRouter.tbSignMessagePage,
      arguments: beaconRequest,
    );
  }

  Future _handleAutonomySignRequest(
          params, String topic, PairingMetadata proposer) async =>
      await _navigationService.navigateTo(
        AppRouter.auSignMessagePage,
        arguments:
            Wc2RequestPayload(params: params, topic: topic, proposer: proposer),
      );

  Future _handleAuEthSendTransactionRequest(
      params, PairingMetadata proposer, String topic) async {
    try {
      final walletIndex = await _accountService.getAccountByAddress(
        chain: 'eip155',
        address: params['address'],
      );
      var transaction = params['transactions'][0] as Map<String, dynamic>;
      if (transaction['data'] == null) {
        transaction['data'] = '';
      }
      if (transaction['gas'] == null) {
        transaction['gas'] = '';
      }
      if (transaction['to'] == null) {
        log.info('[Wc2Service] Invalid transaction: no recipient');
        throw JsonRpcError.invalidParams('Invalid transaction: no recipient');
      }
      final args = WCSendTransactionPageArgs(
        proposer,
        WCEthereumTransaction.fromJson(transaction),
        walletIndex.wallet.uuid,
        walletIndex.index,
        topic: topic,
      );
      return await _navigationService.navigateTo(
        AppRouter.wcSendTransactionPage,
        arguments: args,
      );
    } catch (e) {
      throw JsonRpcError.invalidParams(e.toString());
    }
  }

  Future _handleAuTezSendTransactionRequest(
      params, PairingMetadata proposer, String topic) async {
    try {
      final beaconRequest = getBeaconRequest(
        topic,
        params,
        proposer,
        0,
      );
      return await _navigationService.navigateTo(
        AppRouter.tbSendTransactionPage,
        arguments: beaconRequest,
      );
    } catch (e) {
      throw JsonRpcError.invalidParams(e.toString());
    }
  }
//#endregion
}

class Wc2RequestPayload {
  dynamic params;
  String topic;
  PairingMetadata proposer;

  Wc2RequestPayload({
    required this.params,
    required this.topic,
    required this.proposer,
  });
}
