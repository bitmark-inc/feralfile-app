import 'dart:convert';

import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_connect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_sign_message_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:wallet_connect/wallet_connect.dart';

class WalletConnectService {
  final NavigationService _navigationService;
  final ConfigurationService _configurationService;

  final List<WCClient> wcClients = List.empty(growable: true);

  WalletConnectService(this._navigationService, this._configurationService) {
    final wcSessions = _configurationService.getWCSessions();

    wcSessions.forEach((element) {
      final WCClient wcClient = _createWCClient(element);
      wcClient.connectFromSessionStore(element);
      wcClients.add(wcClient);
    });
  }

  connect(String wcUri) {
    final session = WCSession.from(wcUri);
    final peerMeta = WCPeerMeta(
      name: 'Autonomy',
      url: 'https://bitmark.com',
      description: 'Autonomy Wallet',
      icons: [],
    );

    final wcClient = _createWCClient(null);
    wcClient.connectNewSession(session: session, peerMeta: peerMeta);
    wcClients.add(wcClient);
  }

  disconnect(WCPeerMeta peerMeta) {
    final wcClient = wcClients.firstWhere((element) => element.remotePeerMeta == peerMeta);

    wcClient.disconnect();
    wcClients.remove(wcClient);

    final wcSessions = _configurationService.getWCSessions().toList();
    wcSessions.removeWhere((element) => element.remotePeerMeta == peerMeta);
    _configurationService.setWCSessions(wcSessions);
  }

  approveSession(WCPeerMeta peerMeta, List<String> accounts, int chainId) {
    final wcClient = wcClients.firstWhere((element) => element.remotePeerMeta == peerMeta);

    wcClient.approveSession(accounts: accounts, chainId: chainId);
    _configurationService.setWCSessions([wcClient.sessionStore]);
  }

  rejectSession(WCPeerMeta peerMeta) {
    final wcClient = wcClients.firstWhere((element) => element.remotePeerMeta == peerMeta);

    wcClient.rejectSession();
    wcClients.remove(wcClient);
  }

  approveRequest(WCPeerMeta peerMeta, int id, String result) {
    final wcClient = wcClients.firstWhere((element) => element.remotePeerMeta == peerMeta);

    wcClient.approveRequest<String>(id: id, result: result);
  }

  rejectRequest(WCPeerMeta peerMeta, int id) {
    final wcClient = wcClients.firstWhere((element) => element.remotePeerMeta == peerMeta);

    wcClient.rejectRequest(id: id);
  }

  WCClient _createWCClient(WCSessionStore? sessionStore) {
    WCPeerMeta? currentPeerMeta = sessionStore?.remotePeerMeta;
    return WCClient(
      onConnect: () {
        print("WC connected");
      },
      onDisconnect: (code, reason) {
        print("WC disconnected");
      },
      onFailure: (error) {
        print("WC failed to connect: $error");
      },
      onSessionRequest: (id, peerMeta) {
        currentPeerMeta = peerMeta;
        _navigationService.navigateTo(
            WCConnectPage.tag, arguments: WCConnectPageArgs(id, peerMeta));
      },
      onEthSign: (id, message) {
        _navigationService.navigateTo(WCSignMessagePage.tag,
            arguments: WCSignMessagePageArgs(
                id, currentPeerMeta!, message.data!));
      },
      onEthSendTransaction: (id, tx) {
        _navigationService.navigateTo(WCSendTransactionPage.tag,
            arguments: WCSendTransactionPageArgs(id, currentPeerMeta!, tx));
      },
      onEthSignTransaction: (id, tx) {
        // Respond to eth_signTransaction request callback
      },
    );
  }
}
