import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_connect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_sign_message_page.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:wallet_connect/wallet_connect.dart';

class WalletConnectService {
  final NavigationService navigationService;

  late final WCClient wcClient;

  WalletConnectService(this.navigationService) {
    wcClient = WCClient(
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
        navigationService.navigateTo(WCConnectPage.tag, arguments: WCConnectPageArgs(id, peerMeta));
      },
      onEthSign: (id, message) {
        navigationService.navigateTo(WCSignMessagePage.tag, arguments: WCSignMessagePageArgs(id, wcClient.peerMeta!, message.data!));
      },
      onEthSendTransaction: (id, tx) {
        navigationService.navigateTo(WCSendTransactionPage.tag, arguments: WCSendTransactionPageArgs(id, wcClient.peerMeta!, tx));
      },
      onEthSignTransaction: (id, tx) {
        // Respond to eth_signTransaction request callback
      },
    );
  }

  connect(String wcUri) {
    final session = WCSession.from(wcUri);
    final peerMeta = WCPeerMeta(
      name: 'Autonomy',
      url: 'https://bitmark.com',
      description: 'Autonomy Wallet',
      icons: [],
    );
    wcClient.connectNewSession(session: session, peerMeta: peerMeta);
  }

  disconnect() {
    wcClient.disconnect();
  }

  approveSession(List<String> accounts, int chainId) {
    wcClient.approveSession(accounts: accounts, chainId: chainId);
  }

  rejectSession() {
    wcClient.rejectSession();
  }

  approveRequest(int id, String result) {
    wcClient.approveRequest<String>(id: id, result: result);
  }

  rejectRequest(int id) {
    wcClient.rejectRequest(id: id);
  }
}
