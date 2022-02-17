import 'dart:convert';

import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/model/connection_supports.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_connect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_sign_message_page.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:wallet_connect/wallet_connect.dart';

class WalletConnectService {
  final NavigationService _navigationService;
  final CloudDatabase _cloudDB;

  final List<WCClient> wcClients = List.empty(growable: true);
  Map<WCPeerMeta, String> tmpUuids = Map();

  WalletConnectService(this._navigationService, this._cloudDB) {
    initSessions();
  }

  Future initSessions() async {
    final wcConnections = await _cloudDB.connectionDao
        .getConnectionsByType(ConnectionType.dappConnect.rawValue);
    wcConnections.forEach((element) {
      final WCClient? wcClient = _createWCClient(element);
      final sessionStore = element.wcConnection?.sessionStore;

      if (wcClient == null || sessionStore == null) return;

      wcClient.connectFromSessionStore(
          sessionStore: sessionStore, isWallet: true);
      wcClients.add(wcClient);
    });
  }

  connect(String wcUri) {
    log.info("WalletConnectService.connect: $wcUri");
    final session = WCSession.from(wcUri);
    final peerMeta = WCPeerMeta(
      name: 'Autonomy',
      url: 'https://bitmark.com',
      description: 'Autonomy Wallet',
      icons: [],
    );

    final wcClient = _createWCClient(null);
    if (wcClient == null) return;
    wcClient.connectNewSession(session: session, peerMeta: peerMeta);
    wcClients.add(wcClient);
  }

  disconnect(WCPeerMeta peerMeta) {
    log.info("WalletConnectService.disconnect: $peerMeta");
    final wcClient =
        wcClients.lastWhere((element) => element.remotePeerMeta == peerMeta);

    wcClient.disconnect();
    wcClients.remove(wcClient);
  }

  approveSession(
      String uuid, WCPeerMeta peerMeta, List<String> accounts, int chainId) {
    log.info(
        "WalletConnectService.approveSession: $peerMeta, $accounts, $chainId");
    final wcClient =
        wcClients.lastWhere((element) => element.remotePeerMeta == peerMeta);
    wcClient.approveSession(accounts: accounts, chainId: chainId);

    tmpUuids[peerMeta] = uuid;

    final wcConnection = WalletConnectConnection(
        personaUuid: uuid, sessionStore: wcClient.sessionStore);

    final connection = Connection(
      key: wcClient.remotePeerId!,
      name: peerMeta.name,
      data: json.encode(wcConnection),
      connectionType: ConnectionType.dappConnect.rawValue,
      accountNumber: "",
      createdAt: DateTime.now(),
    );
    _cloudDB.connectionDao.insertConnection(connection);
  }

  rejectSession(WCPeerMeta peerMeta) {
    log.info("WalletConnectService.rejectSession: $peerMeta");
    final wcClient =
        wcClients.lastWhere((element) => element.remotePeerMeta == peerMeta);

    wcClient.rejectSession();
    wcClients.remove(wcClient);
  }

  approveRequest(WCPeerMeta peerMeta, int id, String result) {
    log.info("WalletConnectService.approveRequest: $peerMeta, $result");
    final wcClient =
        wcClients.lastWhere((element) => element.remotePeerMeta == peerMeta);

    wcClient.approveRequest<String>(id: id, result: result);
  }

  rejectRequest(WCPeerMeta peerMeta, int id) {
    log.info("WalletConnectService.rejectRequest: $peerMeta, $id");
    final wcClient =
        wcClients.lastWhere((element) => element.remotePeerMeta == peerMeta);

    wcClient.rejectRequest(id: id);
  }

  WCClient? _createWCClient(Connection? connection) {
    final wcConnection = connection?.wcConnection;
    final sessionStore = wcConnection?.sessionStore;

    WCPeerMeta? currentPeerMeta = sessionStore?.remotePeerMeta;
    return WCClient(
      onConnect: () {
        print("WC connected");
      },
      onDisconnect: (code, reason) {
        wcClients.removeWhere(
            (element) => element.remotePeerId == sessionStore?.remotePeerId);
        print("WC disconnected");
      },
      onFailure: (error) {
        print("WC failed to connect: $error");
      },
      onSessionRequest: (id, peerMeta) {
        currentPeerMeta = peerMeta;
        _navigationService.navigateTo(WCConnectPage.tag,
            arguments: WCConnectPageArgs(id, peerMeta));
      },
      onEthSign: (id, message) async {
        String? uuid = wcConnection?.personaUuid ?? tmpUuids[currentPeerMeta!];
        if (uuid == null) return;

        _navigationService.navigateTo(WCSignMessagePage.tag,
            arguments: WCSignMessagePageArgs(
                id, currentPeerMeta!, message.data!, uuid));
      },
      onEthSendTransaction: (id, tx) {
        String? uuid = wcConnection?.personaUuid ?? tmpUuids[currentPeerMeta!];
        if (uuid == null) return;

        _navigationService.navigateTo(WCSendTransactionPage.tag,
            arguments:
                WCSendTransactionPageArgs(id, currentPeerMeta!, tx, uuid));
      },
      onEthSignTransaction: (id, tx) {
        // Respond to eth_signTransaction request callback
      },
    );
  }
}
