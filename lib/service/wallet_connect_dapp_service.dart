import 'dart:convert';

import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/rand.dart';
import 'package:flutter/cupertino.dart';
import 'package:wallet_connect/models/session/wc_approve_session_response.dart';
import 'package:wallet_connect/wallet_connect.dart';
import 'package:uuid/uuid.dart';

class WalletConnectDappService {
  late WCClient _wcClient;
  late WCSession _wcSession;
  late WCSessionStore _wcSessionStore;
  ValueNotifier<String?> wcURI = ValueNotifier(null);
  late WCPeerMeta _dappPeerMeta;
  ValueNotifier<bool> isConnected = ValueNotifier(false);
  ValueNotifier<List<String>?> remotePeerAccount = ValueNotifier([]);
  final ConfigurationService _configurationService;

  WalletConnectDappService(this._configurationService);

  start() async {
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

    final storedWCSessionString = _configurationService.getWCDappSession();
    if (storedWCSessionString != null) {
      _wcSessionStore =
          WCSessionStore.fromJson(jsonDecode(storedWCSessionString));
      _dappPeerMeta = _wcSessionStore.peerMeta;
      _wcSession = _wcSessionStore.session;
    } else {
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
    }

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
    final storedWCSessionString = _configurationService.getWCDappSession();
    if (storedWCSessionString != null) {
      _wcClient.connectFromSessionStore(
          sessionStore: _wcSessionStore, isWallet: false);
    } else {
      _wcClient.connectNewSession(
          session: _wcSession, peerMeta: _dappPeerMeta, isWallet: false);
    }
  }

  disconnect() {
    _configurationService.setWCDappSession(null);
    _configurationService.setWCDappAccounts(null);
    isConnected.value = false;
    remotePeerAccount.value = [];
    _wcClient.disconnect();
  }

  _onConnect() {
    final accounts = _configurationService.getWCDappAccounts();
    log.info("WC connected, stored accounts: $accounts");
    if (accounts != null) {
      isConnected.value = true;
      remotePeerAccount.value = accounts;
    }
  }

  _onDisconnect(code, reason) {
    log.info("WC disconnected, reason: $reason, code: $code");
    isConnected.value = false;
    if (code == 1005) {
      _configurationService.setWCDappSession(null);
      _configurationService.setWCDappAccounts(null);
      connect();
    }
  }

  _onFailure(error) {
    log.info("WC failed to connect: $error");
  }

  _onSessionRequest(id, peerMeta) {
    log.info("onSessionRequest");
  }

  _onSessionUpdate(id, updatedSession) {
    log.info("WC onSessionUpdate");
    _configurationService.setWCDappSession(null);
    _configurationService.setWCDappAccounts(null);
    remotePeerAccount.value = updatedSession.accounts;
  }

  _onEthSign(id, message) {}

  _onEthSendTransaction(id, tx) {}

  _onEthSignTransaction(id, tx) {
    // Respond to eth_signTransaction request callback
  }

  _onSessionAppoved(int id, WCApproveSessionResponse response) {
    if (response.approved) {
      remotePeerAccount.value = response.accounts;
      isConnected.value = true;
    }

    _storeSession(response);
  }

  _storeSession(WCApproveSessionResponse response) {
    if (response.approved) {
      _wcSessionStore = WCSessionStore(
          session: _wcSession,
          peerMeta: _dappPeerMeta,
          remotePeerMeta: response.peerMeta,
          chainId: response.chainId!,
          peerId: _wcClient.peerId!,
          remotePeerId: response.peerId);
      _configurationService
          .setWCDappSession(jsonEncode(_wcSessionStore.toJson()));
      _configurationService.setWCDappAccounts(response.accounts);
    } else {
      _configurationService.setWCDappSession(null);
      _configurationService.setWCDappAccounts(null);
    }
  }
}
