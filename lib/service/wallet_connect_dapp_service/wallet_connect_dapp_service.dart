import 'dart:convert';

import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_dapp_service/wc_connected_session.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/rand.dart';
import 'package:flutter/cupertino.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wallet_connect/models/session/wc_approve_session_response.dart';
import 'package:wallet_connect/wallet_connect.dart';
import 'package:uuid/uuid.dart';
import 'package:web3dart/web3dart.dart';

class WalletConnectDappService {
  late WCClient _wcClient;
  late WCSession _wcSession;
  late WCSessionStore _wcSessionStore;
  ValueNotifier<String?> wcURI = ValueNotifier(null);
  late WCPeerMeta _dappPeerMeta;
  ValueNotifier<bool> isConnected = ValueNotifier(false);
  ValueNotifier<WCConnectedSession?> remotePeerAccount = ValueNotifier(null);

  final ConfigurationService _configurationService;

  WalletConnectDappService(this._configurationService);

  Future start() async {
    _wcClient = WCClient(
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
          'Autonomy is the home for all your NFT art and other collectibles — a seamless, customizable way to enjoy your collection.',
      icons: [],
    );

    _wcSession = WCSession(
        topic: Uuid().v4(),
        version: "1",
        bridge: "https://walletconnect.bitmark.com",
        key: generateRandomHex(32));

    final encodedBridge = Uri.encodeComponent(_wcSession.bridge);
    wcURI.value = "wc:" +
        _wcSession.topic +
        "@" +
        _wcSession.version +
        "?bridge=" +
        encodedBridge +
        "&key=" +
        _wcSession.key;

    log.info("uri = $wcURI");
  }

  connect() {
    Sentry.startTransaction('WalletConnect_dapp', 'connect');
    Sentry.getSpan()?.setTag("bridgeServer", _wcSession.bridge);
    _wcClient.connectNewSession(
        session: _wcSession, peerMeta: _dappPeerMeta, isWallet: false);
  }

  disconnect() {
    _configurationService.setWCDappSession(null);
    _configurationService.setWCDappAccounts(null);
    isConnected.value = false;
    // remotePeerAccount.value = [];
    _wcClient.disconnect();
  }

  _onConnect() {
    final accounts = _configurationService.getWCDappAccounts();
    log.info("WC connected, stored accounts: $accounts");
    if (accounts != null) {
      isConnected.value = true;
      // remotePeerAccount.value = accounts;
    }
    Sentry.getSpan()?.finish(status: SpanStatus.ok());
  }

  _onDisconnect(code, reason) {
    log.info("WC disconnected, reason: $reason, code: $code");
    isConnected.value = false;
    Sentry.getSpan()?.finish(status: SpanStatus.aborted());
    if (code == 1005) {
      _configurationService.setWCDappSession(null);
      _configurationService.setWCDappAccounts(null);
      connect();
    }
  }

  _onFailure(error) {
    log.info("WC failed to connect: $error");
    Sentry.getSpan()?.finish(status: SpanStatus.internalError());
  }

  _onSessionRequest(id, peerMeta) {
    log.info("onSessionRequest");
  }

  _onSessionUpdate(id, updatedSession) {
    log.info("WC onSessionUpdate");
    _configurationService.setWCDappSession(null);
    _configurationService.setWCDappAccounts(null);
    final connectedSession = WCConnectedSession(
        sessionStore: _wcSessionStore, accounts: updatedSession.accounts);
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
          peerId: _wcClient.peerId!,
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

      final connectedSession =
          WCConnectedSession(sessionStore: _wcSessionStore, accounts: accounts);

      remotePeerAccount.value = connectedSession;
    }
  }
}
