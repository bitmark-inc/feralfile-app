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

import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
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
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/credentials.dart';

class Wc2Service {
  static final Set<String> _supportedChains = {
    Wc2Chain.ethereum,
    Wc2Chain.tezos,
  };

  static final Set<String> supportedMethods = {
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
  final CloudManager _cloudObjects;

  late Web3Wallet _wcClient;
  String pendingUri = '';

  Timer? _timer;

  final List<String> _approvedConnectionKey = [];

  final ValueNotifier<String?> sessionDeleteNotifier =
      ValueNotifier<String?>(null);

  void addApprovedTopic(List<String> keys) {
    _approvedConnectionKey.addAll(keys);
  }

  bool isApprovedTopic(String topic) =>
      _approvedConnectionKey.any((element) => element.contains(topic));

  Wc2Service(
    this._navigationService,
    this._accountService,
    this._cloudObjects,
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
    _wcClient.onSessionDelete.subscribe(_onSessionDeleted);

    _registerEthRequest('${Wc2Chain.ethereum}:${Environment.web3ChainId}');

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
    final chainId = params[0]['chainId'];
    if (chainId != null &&
        BigInt.parse(chainId).toString() !=
            Environment.web3ChainId.toString()) {
      throw _chainNotSupported;
    }
    if (proposer == null) {
      throw _proposalNotFound;
    }
    return await _handleEthSendTransactionRequest(params, proposer, topic);
  }

  Future<PairingMetadata?> _getWc2Request(String topic, params) async {
    final connections = _cloudObjects.connectionObject.getWc2Connections();
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
    final connections = _cloudObjects.connectionObject.getWc2Connections();
    final activeTopics = _wcClient.getActiveSessions().keys;
    log.info('[Wc2Service] activeTopics: $activeTopics');
    final inactiveConnections = connections
        .where((element) =>
            !activeTopics.any((topic) => element.key.contains(topic)))
        .toList();
    await _cloudObjects.connectionObject.deleteConnections(inactiveConnections);
    final keys = connections
        .where((element) => !inactiveConnections.contains(element))
        .map((e) => e.key)
        .toList();
    log.info('[Wc2Service] connection keys: $keys');
    return keys;
  }

  List<SessionRequest> getPendingRequests() =>
      _wcClient.pendingRequests.getAll();

  Future connect(String uri, {Function? onTimeout}) async {
    if (uri.isAutonomyConnectUri) {
      await _connectWithRetry(uri, onTimeout: onTimeout, shouldRetry: true);
    }
  }

  // function connect with retry on timeout 10 seconds
  Future _connectWithRetry(String uri,
      {required bool shouldRetry, Function? onTimeout}) async {
    pendingUri = uri;
    final timer = Timer(CONNECT_FAILED_DURATION, () async {
      if (!shouldRetry) {
        onTimeout?.call();
      }
    });
    final pairingInfo = await _wcClient.pair(uri: Uri.parse(uri));
    if (timer.isActive) {
      timer.cancel();
      log.info('[Wc2Service] pairingInfo: $pairingInfo');
    } else {
      if (shouldRetry) {
        log.info('[Wc2Service] Retry connect to $uri');
        await _connectWithRetry(uri, onTimeout: onTimeout, shouldRetry: false);
      }
    }
  }

  Future cleanup() async {
    final connections = _cloudObjects.connectionObject
        .getConnectionsByType(ConnectionType.dappConnect2.rawValue);

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

  Future approveSession(
    Wc2Proposal proposal, {
    required List<String> accounts,
    required String connectionKey,
    required String accountNumber,
  }) async {
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
      connectionType: ConnectionType.dappConnect2.rawValue,
      accountNumber: accountNumber,
      createdAt: DateTime.now(),
    );
    await _cloudObjects.connectionObject.writeConnection(connection);
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

  Future<void> _onSessionDeleted(SessionDelete? session) async {
    if (session?.topic != null) {
      sessionDeleteNotifier.value = session!.topic;
    }
  }

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
    final wc2Proposal = Wc2Proposal(
      proposal.id,
      proposer: proposal.params.proposer.metadata,
      requiredNamespaces: proposal.params.requiredNamespaces,
      optionalNamespaces: proposal.params.optionalNamespaces,
      validation: proposal.verifyContext?.validation,
    );
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

    if (signType == WCSignType.TYPED_MESSAGE) {
      final typedData = jsonDecode(message);
      final domain = typedData['domain'];
      final chainId = domain?['chainId'];
      if (chainId != null &&
          chainId.toString() != Environment.web3ChainId.toString()) {
        throw _chainNotSupported;
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

//#endregion
}
