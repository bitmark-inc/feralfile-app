import 'dart:convert';

import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/model/connection_supports.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_connect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_sign_message_page.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
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
      final WCClient? wcClient = _createWCClient(null, element);
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

    final wcClient = _createWCClient(session.topic, null);
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

  approveSession(String uuid, WCPeerMeta peerMeta, List<String> accounts,
      int chainId) async {
    log.info(
        "WalletConnectService.approveSession: $peerMeta, $accounts, $chainId");
    final wcClient =
        wcClients.lastWhere((element) => element.remotePeerMeta == peerMeta);
    wcClient.approveSession(accounts: accounts, chainId: chainId);

    tmpUuids[peerMeta] = uuid;

    if (peerMeta.name == AUTONOMY_TV_PEER_NAME) {
      log.info("it's AUTONOMY_TV_PEER_NAME => skip storing connection");
      return;
    }

    final wcConnection = WalletConnectConnection(
        personaUuid: uuid, sessionStore: wcClient.sessionStore);

    final connection = Connection(
      key: wcClient.session!.topic,
      name: peerMeta.name,
      data: json.encode(wcConnection),
      connectionType: ConnectionType.dappConnect.rawValue,
      accountNumber: "",
      createdAt: DateTime.now(),
    );
    await _cloudDB.connectionDao.insertConnection(connection);
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

  WCClient? _createWCClient(String? _topic, Connection? connection) {
    final wcConnection = connection?.wcConnection;
    final sessionStore = wcConnection?.sessionStore;

    final topic = _topic ?? sessionStore?.session.topic;
    if (topic == null) return null;

    WCPeerMeta? currentPeerMeta = sessionStore?.remotePeerMeta;
    return WCClient(
      onConnect: () {
        log.info("WC connected");
      },
      onDisconnect: (code, reason) async {
        log.info("WC disconnected");
        wcClients.removeWhere((element) => element.session == null);

        if (connection != null) {
          _cloudDB.connectionDao.deleteConnection(connection);
        } else {
          final removingConnection =
              await _cloudDB.connectionDao.findById(topic);
          if (removingConnection != null) {
            _cloudDB.connectionDao.deleteConnection(removingConnection);
          }
        }
      },
      onFailure: (error) {
        log.info("WC failed to connect: $error");
      },
      onSessionRequest: (id, peerMeta) {
        currentPeerMeta = peerMeta;
        if (peerMeta.name == AUTONOMY_TV_PEER_NAME) {
          _navigationService.navigateTo(AppRouter.tvConnectPage,
              arguments: WCConnectPageArgs(id, peerMeta));
        } else {
          _navigationService.navigateTo(AppRouter.wcConnectPage,
              arguments: WCConnectPageArgs(id, peerMeta));
        }
      },
      onEthSign: (id, message) async {
        String? uuid = wcConnection?.personaUuid ?? tmpUuids[currentPeerMeta!];
        if (uuid == null) return;

        _navigationService.navigateTo(WCSignMessagePage.tag,
            arguments: WCSignMessagePageArgs(
                id, topic, currentPeerMeta!, message.data!, uuid));
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
