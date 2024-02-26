//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/wc2_pairing.dart';
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
import 'package:autonomy_flutter/util/wc2_channel.dart';
import 'package:autonomy_flutter/util/wc2_ext.dart';
import 'package:autonomy_flutter/util/wc2_tezos_ext.dart';
import 'package:collection/collection.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/credentials.dart';

class Wc2Service extends Wc2Handler {
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

  final NavigationService _navigationService;
  final AccountService _accountService;
  final CloudDatabase _cloudDB;

  late Wc2Channel _wc2channel;
  String pendingUri = '';

  Timer? _timer;

  Wc2Service(
    this._navigationService,
    this._accountService,
    this._cloudDB,
  ) {
    _wc2channel = Wc2Channel(handler: this);
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

  Future connect(String uri, {Function()? onTimeout}) async {
    if (uri.isAutonomyConnectUri) {
      pendingUri = uri;
      _timer?.cancel();
      _timer = Timer(CONNECT_FAILED_DURATION, () {
        onTimeout?.call();
      });
      await _wc2channel.pairClient(uri);
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

    final ids = connections
        .map((e) => e.key.split(':').lastOrNull)
        .whereNotNull()
        .toList();

    unawaited(_wc2channel.cleanup(ids));
  }

  Future approveSession(Wc2Proposal proposal,
      {required String account,
      required String connectionKey,
      required String accountNumber,
      bool isAuConnect = false}) async {
    await _wc2channel.approve(
      proposal.id,
      account,
    );
    final wc2Pairings = await injector<Wc2Service>().getPairings();
    final topic = wc2Pairings
            .firstWhereOrNull((element) => pendingUri.contains(element.topic))
            ?.topic ??
        '';

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
  }

  Future rejectSession(
    String id, {
    String? reason,
  }) async {
    await _wc2channel.reject(
      id,
      reason: reason,
    );
  }

  Future respondOnApprove(String topic, String response) async {
    log.info('[Wc2Service] respondOnApprove topic $topic, response: $response');
    await _wc2channel.respondOnApprove(topic, response);
  }

  Future respondOnReject(
    String topic, {
    String? reason,
  }) async {
    log.info('[Wc2Service] respondOnReject topic $topic, reason: $reason');
    await _wc2channel.respondOnReject(
      topic: topic,
      reason: reason,
    );
  }

  //#region Pairing
  Future<List<Wc2Pairing>> getPairings() async =>
      await _wc2channel.getPairings();

  Future deletePairing({required String topic}) async {
    log.info('[Wc2Service] Delete pairing. Topic: $topic');
    return await _wc2channel.deletePairing(topic: topic);
  }

  //#endregion

  //#region Events handling
  @override
  void onSessionProposal(Wc2Proposal proposal) async {
    log.info('[WC2Service] onSessionProposal: id = ${proposal.id}');
    _timer?.cancel();
    final unsupportedChains =
        proposal.requiredNamespaces.keys.toSet().difference(_supportedChains);
    if (unsupportedChains.isNotEmpty) {
      log.info('[Wc2Service] Proposal contains unsupported chains: '
          '$unsupportedChains');
      await rejectSession(
        proposal.id,
        reason: "Chains ${unsupportedChains.join(", ")} not supported",
      );
      return;
    }

    final proposalMethods = proposal.requiredNamespaces.values
        .map((e) => e.methods)
        .flattened
        .toSet();
    final unsupportedMethods = proposalMethods.difference(supportedMethods);
    if (unsupportedMethods.isNotEmpty) {
      log.info('[Wc2Service] Proposal contains unsupported methods: '
          '$unsupportedMethods');
    }
    unawaited(_navigationService.navigateTo(AppRouter.wc2ConnectPage,
        arguments: proposal));
  }

  @override
  void onSessionRequest(Wc2Request request) async {
    switch (request.method) {
      case 'au_sign':
        switch (request.chainId.caip2Namespace) {
          case Wc2Chain.ethereum:
            await _handleEthereumSignRequest(
                request, WCSignType.PERSONAL_MESSAGE);
            break;
          case Wc2Chain.tezos:
            await _handleTezosSignRequest(request);
            break;
          case Wc2Chain.autonomy:
            await _handleAutonomySignRequest(request);
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
        unawaited(_navigationService.navigateTo(
          AppRouter.wc2PermissionPage,
          arguments: request,
        ));
        break;
      case 'au_sendTransaction':
        final chain = request.params['chain'] as String;
        switch (chain.caip2Namespace) {
          case Wc2Chain.ethereum:
            unawaited(_handleEthereumSendTransactionRequest(request));
            break;
          case Wc2Chain.tezos:
            try {
              final beaconReq = request.toBeaconRequest();
              unawaited(_navigationService.navigateTo(
                AppRouter.tbSendTransactionPage,
                arguments: beaconReq,
              ));
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
        await _handleWC2EthereumSendTransactionRequest(request);
        break;
      case 'personal_sign':
        await _handleWC2EthereumSignRequest(
            request, WCSignType.PERSONAL_MESSAGE);
        break;
      case 'eth_signTypedData':
      case 'eth_signTypedData_v4':
        await _handleWC2EthereumSignRequest(request, WCSignType.TYPED_MESSAGE);
        break;
      case 'eth_sign':
        await _handleWC2EthereumSignRequest(request, WCSignType.MESSAGE);
        break;
      default:
        log.info('[Wc2Service] Unsupported method: ${request.method}');

        unawaited(Sentry.captureMessage(
          '[Wc2Service] Unsupported method: ${request.method}',
          params: [request.toJson()],
        ));
        await respondOnReject(
          request.topic,
          reason: 'Method ${request.method} is not supported',
        );
    }
  }

  //#endregion
  Future _handleWC2EthereumSignRequest(
      Wc2Request request, WCSignType signType) async {
    String address;
    String message;
    if (signType == WCSignType.PERSONAL_MESSAGE) {
      address = request.params[1];
      message = request.params[0];
    } else {
      address = request.params[0];
      if (request.params[1].runtimeType != String) {
        message = jsonEncode(request.params[1]);
      } else {
        message = request.params[1];
      }
    }

    final eip55address = EthereumAddress.fromHex(address).hexEip55;
    final wallet = await _accountService.getAccountByAddress(
      chain: 'eip155',
      address: eip55address,
    );
    await _navigationService.navigateTo(AppRouter.wcSignMessagePage,
        arguments: WCSignMessagePageArgs(
          request.id,
          request.topic,
          request.proposer!,
          message,
          signType,
          wallet.wallet.uuid,
          wallet.index,
          isWalletConnect2: true,
        ));
  }

  Future _handleWC2EthereumSendTransactionRequest(Wc2Request request) async {
    try {
      var transaction = request.params[0] as Map<String, dynamic>;
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
        await respondOnReject(
          request.topic,
          reason: 'Invalid transaction: no recipient',
        );
        return;
      }
      final metaData = request.proposer != null
          ? request.proposer!
          : AppMetadata(icons: [], name: '', url: '', description: '');
      final args = WCSendTransactionPageArgs(
        request.id,
        metaData,
        WCEthereumTransaction.fromJson(transaction),
        walletIndex.wallet.uuid,
        walletIndex.index,
        topic: request.topic,
        isWalletConnect2: true,
      );
      unawaited(_navigationService.navigateTo(
        AppRouter.wcSendTransactionPage,
        arguments: args,
      ));
    } catch (e) {
      await respondOnReject(request.topic, reason: '$e');
    }
  }

  //#region Handle sign request
  Future _handleEthereumSignRequest(
      Wc2Request request, WCSignType signType) async {
    await _navigationService.navigateTo(AppRouter.wcSignMessagePage,
        arguments: WCSignMessagePageArgs(
          request.id,
          request.topic,
          request.proposer!,
          request.params['message'],
          signType,
          '',
          0,
          // uuid, index, used for Wallet connect 1 only
          wc2Params: Wc2SignRequestParams(
            chain: request.params['chain'],
            address: request.params['address'],
            message: request.params['message'],
          ),
        ));
  }

  Future _handleTezosSignRequest(Wc2Request request) async {
    final beaconReq = request.toBeaconRequest();
    await _navigationService.navigateTo(
      AppRouter.tbSignMessagePage,
      arguments: beaconReq,
    );
  }

  Future _handleAutonomySignRequest(Wc2Request request) async {
    await _navigationService.navigateTo(
      AppRouter.auSignMessagePage,
      arguments: request,
    );
  }

  Future _handleEthereumSendTransactionRequest(Wc2Request request) async {
    try {
      final walletIndex = await _accountService.getAccountByAddress(
        chain: 'eip155',
        address: request.params['address'],
      );
      var transaction =
          request.params['transactions'][0] as Map<String, dynamic>;
      if (transaction['data'] == null) {
        transaction['data'] = '';
      }
      if (transaction['gas'] == null) {
        transaction['gas'] = '';
      }
      if (transaction['to'] == null) {
        log.info('[Wc2Service] Invalid transaction: no recipient');
        await respondOnReject(
          request.topic,
          reason: 'Invalid transaction: no recipient',
        );
        return;
      }
      final metaData = request.proposer != null
          ? request.proposer!
          : AppMetadata(icons: [], name: '', url: '', description: '');
      final args = WCSendTransactionPageArgs(
        request.id,
        metaData,
        WCEthereumTransaction.fromJson(transaction),
        walletIndex.wallet.uuid,
        walletIndex.index,
        topic: request.topic,
        isWalletConnect2: true,
      );
      unawaited(_navigationService.navigateTo(
        AppRouter.wcSendTransactionPage,
        arguments: args,
      ));
    } catch (e) {
      await respondOnReject(request.topic, reason: '$e');
    }
  }
//#endregion
}
