//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_dapp_service/wc_connected_session.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/rand.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet_connect/models/session/wc_approve_session_response.dart';
import 'package:wallet_connect/wallet_connect.dart';
import 'package:web3dart/web3dart.dart';

class WalletConnectDappService {
  WCClient? _wcClient;
  late WCSession _wcSession;
  WCSessionStore? _wcSessionStore;
  ValueNotifier<String?> wcURI = ValueNotifier(null);
  late WCPeerMeta _dappPeerMeta;
  ValueNotifier<bool> isConnected = ValueNotifier(false);
  ValueNotifier<WCConnectedSession?> remotePeerAccount = ValueNotifier(null);
  bool waitingForConnection = false;

  final ConfigurationService _configurationService;

  WalletConnectDappService(this._configurationService);

  Timer? _timeoutTimer;

  start() {
    _wcClient ??= WCClient(
      onSessionRequest: _onSessionRequest,
      onSessionUpdate: _onSessionUpdate,
      onFailure: _onFailure,
      onDisconnect: _onDisconnect,
      onEthSign: _onEthSign,
      onEthSignTransaction: _onEthSignTransaction,
      onEthSendTransaction: _onEthSendTransaction,
      onCustomRequest: (_, __) {},
      onConnect: _onConnect,
      onSessionApproved: _onSessionAppoved,
    );

    _dappPeerMeta = WCPeerMeta(
      name: 'Autonomy',
      url: 'https://autonomy.io',
      description:
          'Autonomy is the home for all your NFT art and other collectibles —'
          ' a seamless, customizable way to enjoy your collection.',
      icons: [],
    );

    _wcSession = WCSession(
        topic: const Uuid().v4(),
        version: "1",
        bridge: "https://walletconnect.bitmark.com",
        key: generateRandomHex(32));

    final encodedBridge = Uri.encodeComponent(_wcSession.bridge);
    wcURI.value = "wc:${_wcSession.topic}@${_wcSession.version}?bridge="
        "$encodedBridge&key=${_wcSession.key}";

    log.info("uri = $wcURI");
  }

  connect() {
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      showErrorDialogFromException(LinkingFailedException());
    });

    Sentry.startTransaction('WalletConnect_dapp', 'connect');
    Sentry.getSpan()?.setTag("bridgeServer", _wcSession.bridge);
    _wcClient?.connectNewSession(
        session: _wcSession, peerMeta: _dappPeerMeta, isWallet: false);
  }

  disconnect() {
    _configurationService.setWCDappSession(null);
    _configurationService.setWCDappAccounts(null);
    isConnected.value = false;
    // remotePeerAccount.value = [];
    waitingForConnection = false;
    _wcClient?.disconnect();
  }

  _onConnect() {
    _timeoutTimer?.cancel();
    final accounts = _configurationService.getWCDappAccounts();
    log.info("WC connected, stored accounts: $accounts");
    waitingForConnection = true;
    if (accounts != null) {
      isConnected.value = true;
      // remotePeerAccount.value = accounts;
    }
    Sentry.getSpan()?.finish(status: const SpanStatus.ok());
  }

  _onDisconnect(code, reason) {
    log.info("WC disconnected, reason: $reason, code: $code");
    isConnected.value = false;
    if (waitingForConnection) {
      final context = injector<NavigationService>().navigatorKey.currentContext;
      if (context != null) {
        UIHelper.showMessageAction(
            context, "timeout".tr(), "sorry_the_request_has_timeout".tr(),
            actionButton: "try_again".tr(), onAction: () {
          Navigator.of(context).pop();
          start();
          connect();
        });
      }
    }
    Sentry.getSpan()?.finish(status: const SpanStatus.aborted());
  }

  _onFailure(error) {
    log.info("WC failed to connect: $error");
    Sentry.getSpan()?.finish(status: const SpanStatus.internalError());
    showErrorDialogFromException(LinkingFailedException());
  }

  _onSessionRequest(id, peerMeta) {
    log.info("onSessionRequest");
  }

  _onSessionUpdate(id, updatedSession) {
    log.info("WC onSessionUpdate");
    if (_wcSessionStore == null) return;
    _configurationService.setWCDappSession(null);
    _configurationService.setWCDappAccounts(null);
    final connectedSession = WCConnectedSession(
        sessionStore: _wcSessionStore!, accounts: updatedSession.accounts);
    remotePeerAccount.value = connectedSession;
  }

  _onEthSign(id, message) {}

  _onEthSendTransaction(id, tx) {}

  _onEthSignTransaction(id, tx) {
    // Respond to eth_signTransaction request callback
  }

  _onSessionAppoved(int id, WCApproveSessionResponse response) {
    log.info("WC _onSessionAppoved, reason: $response");
    if (response.approved) {
      _wcSessionStore = WCSessionStore(
          session: _wcSession,
          peerMeta: _dappPeerMeta,
          remotePeerMeta: response.peerMeta,
          chainId: response.chainId!,
          peerId: _wcClient!.peerId!,
          remotePeerId: response.peerId);

      late List<String> accounts;
      try {
        accounts = response.accounts
            .map((e) => EthereumAddress.fromHex(e).hexEip55)
            .toList();
      } catch (error) {
        log.shout(error);
        accounts = response.accounts;
      }

      final connectedSession = WCConnectedSession(
          sessionStore: _wcSessionStore!, accounts: accounts);

      remotePeerAccount.value = connectedSession;
    }

    // Disconnect session after getting address
    disconnect();
  }
}
