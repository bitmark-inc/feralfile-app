//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/model/wc_ethereum_transaction.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/au_sign_message_page.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_sign_message_page.dart';
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

import '../database/cloud_database.dart';
import '../database/entity/connection.dart';

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
    'eth_signTransaction'
  };

  static final Set<String> autonomyMethods = {
    'au_sign',
    'au_permissions',
    'au_sendTransaction',
  };
  static const PairingMetadata pairingMetadata = PairingMetadata(
    name: 'Autonomy',
    description: 'Autonomy Wallet',
    url: 'https://autonomy.io',
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

  Map<Future<ApproveResponse>, PairingMetadata>? _tempApproveResponse;

  Timer? _timer;

  Wc2Service(
    this._navigationService,
    this._accountService,
    this._cloudDB,
  ) {
    init();
  }

  Future<void> init() async {
    _wcClient = await Web3Wallet.createInstance(
      projectId: '33abc0fd433c7a6e1cc198273e4a7d6e',
      metadata: pairingMetadata,
    );
    _wcClient.onSessionProposal.subscribe(_onSessionProposal);
    _registerEthRequest('${Wc2Chain.ethereum}:${Environment.web3ChainId}');
    _registerAutonomyRequest(
        '${Wc2Chain.autonomy}:${Environment.appTestnetConfig ? 1 : 0}');
  }

  void _registerEthRequest(String chainId) {
    _wcClient.registerRequestHandler(
        chainId: chainId,
        method: 'personal_sign',
        handler: _handleEthPersonalSign);
    _wcClient.registerRequestHandler(
        chainId: chainId, method: 'eth_sign', handler: _handleEthSign);
    _wcClient.registerRequestHandler(
        chainId: chainId,
        method: 'eth_signTypedData',
        handler: _handleEthSignType);
    _wcClient.registerRequestHandler(
        chainId: chainId,
        method: 'eth_signTypedData_v4',
        handler: _handleEthSignType);
    _wcClient.registerRequestHandler(
        chainId: chainId,
        method: 'eth_sendTransaction',
        handler: _handleEthSendTx);
    _wcClient.registerRequestHandler(
        chainId: chainId, method: 'au_sign', handler: _handleAuSignEth);
    _wcClient.registerRequestHandler(
        chainId: chainId,
        method: 'au_sendTransaction',
        handler: _handleAuSendEthTx);
  }

  void _registerAutonomyRequest(String chainId) {
    _wcClient..registerRequestHandler(
        chainId: chainId, method: 'au_sign', handler: _handleAuSign)
    ..registerRequestHandler(
        chainId: chainId,
        method: 'au_permissions',
        handler: _handleAuPermissions);
  }

  Future _handleAuPermissions(String topic, params) async {
    log.info('[Wc2Service] received autonomy-au_permissions request $params');
    final proposer = await _getWc2Request(topic, params);
    if (proposer == null) {
      throw const JsonRpcError(code: 301, message: 'proposer not found');
    }
    final result = await _navigationService.navigateTo(
      AppRouter.wc2PermissionPage,
      arguments:
          Wc2RequestPayload(params: params, topic: topic, proposer: proposer),
    );
    if (result is bool && !result) {
      throw const JsonRpcError(code: 300, message: 'User rejected');
    } else {
      return result;
    }
  }

  Future _handleAuSign(String topic, params) async {
    log.info('[Wc2Service] received autonomy-au_sign request $params');
    final proposer = await _getWc2Request(topic, params);
    if (proposer == null) {
      throw const JsonRpcError(code: 301, message: 'proposer not found');
    }
    return await _handleAutonomySignRequest(topic, params, proposer);
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
      throw const JsonRpcError(code: 301, message: 'proposer not found');
    }
    return await _handleWC2EthereumSignRequest(
        params, topic, proposer, wcSignType);
  }

  Future _handleEthSendTx(String topic, params) async {
    log.info('[Wc2Service] received eip155-eth_sendTx request $params');
    final proposer = await _getWc2Request(topic, params);
    if (proposer == null) {
      throw const JsonRpcError(code: 301, message: 'proposer not found');
    }
    await _handleEthSendTransactionRequest(params, proposer, topic);
  }

  Future _handleAuSignEth(String topic, params) async {
    log.info('[Wc2Service] received eip155-au_sign request $params');
    final proposer = await _getWc2Request(topic, params);
    if (proposer == null) {
      throw const JsonRpcError(code: 301, message: 'proposer not found');
    }
    return await _handleEthereumSignRequest(
        params, proposer, topic, WCSignType.PERSONAL_MESSAGE);
  }

  Future _handleAuSendEthTx(String topic, params) async {
    log.info('[Wc2Service] received eip155-au_sign request $params');
    final proposer = await _getWc2Request(topic, params);
    if (proposer == null) {
      throw const JsonRpcError(code: 301, message: 'proposer not found');
    }
    return await _handleAuEthSendTransactionRequest(params, proposer, topic);
  }

  Future<PairingMetadata?> _getWc2Request(String topic, params) async {
    final connections = await _cloudDB.connectionDao.getWc2Connections();
    final connection =
        connections.firstWhereOrNull((element) => element.key.contains(topic));
    if (connection != null) {
      final proposer = PairingMetadata.fromJson(jsonDecode(connection.data));
      return proposer;
    }

    if (_tempApproveResponse != null) {
      print('temp approve response $_tempApproveResponse');
      final approveResponse = await _tempApproveResponse!.keys.toList().first;
      print('approveResponse $approveResponse');
      if (approveResponse.topic == topic) {
        return _tempApproveResponse!.values.toList().first;
      }
    }

    log.warning('[Wc2Service] proposer not found for $topic');
    return null;
  }

  // These session are approved but addresses permission are not granted.
  final List<String> _pendingSessions = [];

  void addPendingSession(String id) {
    _pendingSessions.add(id);
  }

  String? getFirstSession() {
    if (_pendingSessions.isEmpty) {
      return null;
    }
    return _pendingSessions.first;
  }

  void removePendingSession(String id) {
    _pendingSessions.remove(id);
  }

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
    final resF = _wcClient.approveSession(
      id: proposal.id,
      namespaces: proposal.requiredNamespaces
          .map((key, value) => MapEntry(key, value.toNameSpace(accounts))),
    );
    _tempApproveResponse = {resF: proposal.proposer};
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
    if (isAuConnect) {
      addPendingSession(topic);
    }
    _tempApproveResponse = null;

    print('delete temp');
  }

  Future rejectSession(
    int id, {
    String? reason,
  }) async {
    await _wcClient.rejectSession(
        id: id,
        reason: WalletConnectError(
            code: 300, message: reason ?? 'Rejected by user'));
  }

  Future respondOnApprove(String topic, String response) async {
    log.info('[Wc2Service] respondOnApprove topic $topic, response: $response');
    //await _wc2channel.respondOnApprove(topic, response);
  }

  Future respondOnReject(
    String topic, {
    String? reason,
  }) async {
    log.info('[Wc2Service] respondOnReject topic $topic, reason: $reason');
  }

  //#region Pairing

  Future deletePairing({required String topic}) async {
    log.info('[Wc2Service] Delete pairing. Topic: $topic');
    //return await _wc2channel.deletePairing(topic: topic);
  }

  //#endregion

  //#region Events handling

  void _onSessionProposal(SessionProposalEvent? proposal) async {
    if (proposal == null) {
      return;
    }
    log.info('[WC2Service] onSessionProposal: id = ${proposal.id}');

    log.info(
        '[WC2Service] onSessionProposal: topic = ${proposal.params.pairingTopic}');
    log.info(
        '[WC2Service] onSessionProposal: sessionProperties = ${proposal.params.sessionProperties}');
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
        requiredNamespaces: proposal.params.requiredNamespaces);
    _navigationService.navigateTo(AppRouter.wc2ConnectPage,
        arguments: wc2Proposal);
  }

  Future<void> onSessionRequest(Wc2Request request) async {
    switch (request.method) {
      case 'au_sign':
        switch (request.chainId.caip2Namespace) {
          case Wc2Chain.ethereum:
            //await _handleEthereumSignRequest(
            //  request, WCSignType.PERSONAL_MESSAGE);
            break;
          case Wc2Chain.tezos:
            await _handleTezosSignRequest(request);
            break;
          case Wc2Chain.autonomy:
            //await _handleAutonomySignRequest(request);
            break;
          default:
            log.info('[Wc2Service] Unsupported chain: ${request.method}');
            await respondOnReject(
              request.topic,
              reason: 'Chain ${request.chainId} is not supported',
            );
        }
        break;
      case 'au_permissions':
        _navigationService.navigateTo(
          AppRouter.wc2PermissionPage,
          arguments: request,
        );
        break;
      case 'au_sendTransaction':
        final chain = request.params['chain'] as String;
        switch (chain.caip2Namespace) {
          case Wc2Chain.ethereum:
            //_handleAuEthSendTransactionRequest(request);
            break;
          case Wc2Chain.tezos:
            try {
              final beaconReq = request.toBeaconRequest();
              _navigationService.navigateTo(
                TBSendTransactionPage.tag,
                arguments: beaconReq,
              );
            } catch (e) {
              await respondOnReject(request.topic, reason: '$e');
            }
            break;
          default:
            await respondOnReject(
              request.topic,
              reason: 'Chain $chain is not supported',
            );
        }
        break;
      case 'eth_sendTransaction':
        //await _handleEthSendTransactionRequest(request);
        break;
      case 'personal_sign':
        //await _handleWC2EthereumSignRequest(
        //  request, WCSignType.PERSONAL_MESSAGE);
        break;
      case 'eth_signTypedData':
      case 'eth_signTypedData_v4':
        //await _handleWC2EthereumSignRequest(request, WCSignType.TYPED_MESSAGE);
        break;
      case 'eth_sign':
        //await _handleWC2EthereumSignRequest(request, WCSignType.MESSAGE);
        break;
      default:
        log.info('[Wc2Service] Unsupported method: ${request.method}');
        await respondOnReject(
          request.topic,
          reason: 'Method ${request.method} is not supported',
        );
    }
  }

  //#endregion
  Future _handleWC2EthereumSignRequest(params, String topic,
      PairingMetadata proposer, WCSignType signType) async {
    String address, message;
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
    final result = await _navigationService.navigateTo(WCSignMessagePage.tag,
        arguments: WCSignMessagePageArgs(
          topic,
          proposer,
          message,
          signType,
          wallet.wallet.uuid,
          wallet.index,
        ));
    if (result is bool && !result) {
      throw const JsonRpcError(code: 300, message: 'User rejected');
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
        throw const JsonRpcError(
            code: 302, message: 'Invalid transaction: no recipient');
      }
      final args = WCSendTransactionPageArgs(
        proposer,
        WCEthereumTransaction.fromJson(transaction),
        walletIndex.wallet.uuid,
        walletIndex.index,
        topic: topic,
      );
      return await _navigationService.navigateTo(
        WCSendTransactionPage.tag,
        arguments: args,
      );
    } catch (e) {
      throw JsonRpcError.invalidParams(e.toString());
    }
  }

  //#region Handle sign request
  Future _handleEthereumSignRequest(params, PairingMetadata proposer,
      String topic, WCSignType signType) async {
    return await _navigationService.navigateTo(WCSignMessagePage.tag,
        arguments: WCSignMessagePageArgs(
          topic,
          proposer,
          params['message'],
          signType,
          '',
          0,
        ));
  }

  Future _handleTezosSignRequest(Wc2Request request) async {
    final beaconReq = request.toBeaconRequest();
    await _navigationService.navigateTo(
      TBSignMessagePage.tag,
      arguments: beaconReq,
    );
  }

  Future _handleAutonomySignRequest(
      params, String topic, PairingMetadata proposer) async {
    return await _navigationService.navigateTo(
      AUSignMessagePage.tag,
      arguments:
          Wc2RequestPayload(params: params, topic: topic, proposer: proposer),
    );
  }

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
        throw const JsonRpcError(
            code: 302, message: 'Invalid transaction: no recipient');
      }
      final args = WCSendTransactionPageArgs(
        proposer,
        WCEthereumTransaction.fromJson(transaction),
        walletIndex.wallet.uuid,
        walletIndex.index,
        topic: topic,
      );
      return await _navigationService.navigateTo(
        WCSendTransactionPage.tag,
        arguments: args,
      );
    } catch (e) {
      throw JsonRpcError.invalidParams(e.toString());
    }
  }
//#endregion
}

//enum WCSignType { MESSAGE, PERSONAL_MESSAGE, TYPED_MESSAGE }

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
