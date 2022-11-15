//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/model/connection_supports.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_connect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_sign_message_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';
import 'package:wallet_connect/wallet_connect.dart';

import '../main.dart';

class WalletConnectService {
  final NavigationService _navigationService;
  final CloudDatabase _cloudDB;
  final ConfigurationService _configurationService;

  final List<WCClient> wcClients = List.empty(growable: true);
  Map<WCPeerMeta, String> tmpUuids = {};

  WalletConnectService(
    this._navigationService,
    this._cloudDB,
    this._configurationService,
  );

  Future initSessions({bool forced = false}) async {
    final wcConnections = await _cloudDB.connectionDao
        .getConnectionsByType(ConnectionType.dappConnect.rawValue);
    // check if the service is already initiate
    if (wcClients.isNotEmpty && !forced) {
      return;
    }

    for (var element in wcConnections) {
      if (wcClients.any((client) => client.session?.topic == element.key)) {
        continue;
      }

      final WCClient? wcClient = _createWCClient(null, element);
      final sessionStore = element.wcConnection?.sessionStore;

      if (wcClient == null || sessionStore == null) continue;

      wcClient.connectFromSessionStore(sessionStore: sessionStore);
      wcClients.add(wcClient);
    }
  }

  connect(String wcUri) {
    log.info("WalletConnectService.connect: $wcUri");
    final session = WCSession.from(wcUri);
    final peerMeta = WCPeerMeta(
      name: 'Autonomy',
      url: 'https://autonomy.io',
      description: 'Autonomy Wallet',
      icons: [],
    );

    final wcClient = _createWCClient(session.topic, null);
    if (wcClient == null) {
      memoryValues.deepLink.value = null;
      return;
    }
    try {
      wcClient.connectNewSession(session: session, peerMeta: peerMeta);
      wcClients.add(wcClient);
    } catch (_) {
      memoryValues.deepLink.value = null;
    }
  }

  disconnect(WCPeerMeta peerMeta) {
    log.info("WalletConnectService.disconnect: $peerMeta");
    final wcClient = wcClients
        .lastWhereOrNull((element) => element.remotePeerMeta == peerMeta);

    if (wcClient == null) return;

    wcClient.disconnect();
    wcClients.remove(wcClient);
  }

  Future<bool> approveSession(String uuid, WCPeerMeta peerMeta,
      List<String> accounts, int chainId) async {
    log.info(
        "WalletConnectService.approveSession: $peerMeta, $accounts, $chainId");
    final wcClient = wcClients
        .lastWhereOrNull((element) => element.remotePeerMeta == peerMeta);
    if (wcClient == null) return false;

    wcClient.approveSession(accounts: accounts, chainId: chainId);

    tmpUuids[peerMeta] = uuid;

    if (peerMeta.name == AUTONOMY_TV_PEER_NAME) {
      final date = peerMeta.description?.split(' -').last;
      final microsecondsSinceEpoch = int.tryParse(date ?? '');
      if (microsecondsSinceEpoch == null) return true;
      final expiredTime =
          DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch);
      if (expiredTime.isBefore(DateTime.now())) {
        return false;
      }
      log.info("it's AUTONOMY_TV_PEER_NAME => skip storing connection");
      return true;
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
    return true;
  }

  rejectSession(WCPeerMeta peerMeta) {
    log.info("WalletConnectService.rejectSession: $peerMeta");
    final wcClient = wcClients
        .lastWhereOrNull((element) => element.remotePeerMeta == peerMeta);

    if (wcClient == null) return;

    wcClient.rejectSession();
    wcClients.remove(wcClient);
  }

  approveRequest(WCPeerMeta peerMeta, int id, String result) {
    log.info("WalletConnectService.approveRequest: $peerMeta, $result");
    final wcClient = wcClients
        .lastWhereOrNull((element) => element.remotePeerMeta == peerMeta);

    if (wcClient == null) return;

    wcClient.approveRequest<String>(id: id, result: result);
  }

  rejectRequest(WCPeerMeta peerMeta, int id) {
    log.info("WalletConnectService.rejectRequest: $peerMeta, $id");
    final wcClient = wcClients
        .lastWhereOrNull((element) => element.remotePeerMeta == peerMeta);

    if (wcClient == null) return;

    wcClient.rejectRequest(id: id);
  }

  WCClient? _createWCClient(String? sessionTopic, Connection? connection) {
    final wcConnection = connection?.wcConnection;
    final sessionStore = wcConnection?.sessionStore;

    final topic = sessionTopic ?? sessionStore?.session.topic;
    if (topic == null) return null;

    WCPeerMeta? currentPeerMeta = sessionStore?.remotePeerMeta;
    return WCClient(
      onConnect: () {
        log.info("WC connected");
      },
      onDisconnect: (code, reason) async {
        log.info("WC disconnected");
        wcClients.removeWhere((element) =>
            element.session == null &&
            !(element.remotePeerMeta?.url.contains("feralfile") ?? false));
      },
      onFailure: (error) {
        log.info("WC failed to connect: $error");
      },
      onSessionRequest: (id, peerMeta) async {
        currentPeerMeta = peerMeta;
        if (peerMeta.name == AUTONOMY_TV_PEER_NAME) {
          final isSubscribed = await injector<IAPService>().isSubscribed();
          final jwt = _configurationService.getIAPJWT();
          if ((jwt != null && jwt.isValid(withSubscription: true)) ||
              isSubscribed) {
            _navigationService.navigateTo(AppRouter.tvConnectPage,
                arguments: WCConnectPageArgs(id, peerMeta));
            injector<WalletConnectService>()
                .approveRequest(peerMeta, id, 'ScanSuccess');
          } else {
            //rejectRequest(peerMeta, id);
            _configurationService.setTVConnectData(peerMeta, id);
            throw RequiredPremiumFeature(
                feature: PremiumFeature.AutonomyTV, peerMeta: peerMeta, id: id);
          }
        } else {
          _navigationService.navigateTo(AppRouter.wcConnectPage,
              arguments: WCConnectPageArgs(id, peerMeta));
        }
      },
      onEthSign: (id, message) async {
        String? uuid = wcConnection?.personaUuid ?? tmpUuids[currentPeerMeta!];
        if (uuid == null ||
            !wcClients.any(
                (element) => element.remotePeerMeta == currentPeerMeta)) return;

        _navigationService.navigateTo(WCSignMessagePage.tag,
            arguments: WCSignMessagePageArgs(
                id, topic, currentPeerMeta!, message.data!, uuid));
      },
      onEthSendTransaction: (id, tx) {
        String? uuid = wcConnection?.personaUuid ?? tmpUuids[currentPeerMeta!];
        if (uuid == null ||
            !wcClients.any(
                (element) => element.remotePeerMeta == currentPeerMeta)) return;

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
