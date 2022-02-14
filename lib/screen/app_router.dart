import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/screen/account/name_persona_page.dart';
import 'package:autonomy_flutter/screen/account/new_account_page.dart';
import 'package:autonomy_flutter/screen/be_own_gallery_page.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/router/router_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_page.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_page.dart';
import 'package:autonomy_flutter/screen/onboarding_page.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/receive_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_review_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_page.dart';
import 'package:autonomy_flutter/screen/settings/networks/select_network_bloc.dart';
import 'package:autonomy_flutter/screen/settings/networks/select_network_page.dart';
import 'package:autonomy_flutter/screen/settings/settings_bloc.dart';
import 'package:autonomy_flutter/screen/settings/settings_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_bloc.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_connect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_disconnect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_sign_message_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_connect/wallet_connect.dart';

class AppRouter {
  static const beOwnGalleryPage = 'be_own_gallery';
  static const newAccountPage = "new_account";
  static const namePersonaPage = "name_persona_page";
  static const homePage = "home_page";

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final networkInjector = injector<NetworkConfigInjector>();

    switch (settings.name) {
      case homePage:
        return CupertinoPageRoute(
            builder: (context) => BlocProvider(
                  create: (_) => HomeBloc(networkInjector.I(), injector(),
                      injector(), networkInjector.I<AppDatabase>().assetDao),
                  child: HomePage(),
                ));
      case beOwnGalleryPage:
        return CupertinoPageRoute(
          builder: (context) => BeOwnGalleryPage(),
        );
      case AppRouter.newAccountPage:
        return CupertinoPageRoute(
            builder: (context) => BlocProvider(
                create: (_) => PersonaBloc(injector<CloudDatabase>()),
                child: NewAccountPage()));

      case AppRouter.namePersonaPage:
        return CupertinoPageRoute(
            builder: (context) => BlocProvider(
                  create: (_) => PersonaBloc(injector<CloudDatabase>()),
                  child: NamePersonaPage(uuid: settings.arguments as String),
                ));
      case WCConnectPage.tag:
        return CupertinoPageRoute(
          builder: (context) =>
              WCConnectPage(args: settings.arguments as WCConnectPageArgs),
        );
      case WCDisconnectPage.tag:
        return CupertinoPageRoute(
          builder: (context) =>
              WCDisconnectPage(client: settings.arguments as WCClient),
        );
      case WCSignMessagePage.tag:
        return CupertinoPageRoute(
          builder: (context) => WCSignMessagePage(
              args: settings.arguments as WCSignMessagePageArgs),
        );
      case WCSendTransactionPage.tag:
        return CupertinoPageRoute(
          builder: (context) => BlocProvider(
            create: (_) => WCSendTransactionBloc(
                injector(), networkInjector.I(), injector()),
            child: WCSendTransactionPage(
                args: settings.arguments as WCSendTransactionPageArgs),
          ),
        );
      case ScanQRPage.tag:
        return CupertinoPageRoute(
            fullscreenDialog: true,
            builder: (context) => ScanQRPage(
                  scannerItem: settings.arguments as ScannerItem,
                ));
      case SettingsPage.tag:
        return CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) => BlocProvider(
            create: (_) => SettingsBloc(
                injector(), networkInjector.I(), networkInjector.I()),
            child: SettingsPage(),
          ),
        );
      case WalletDetailPage.tag:
        return CupertinoPageRoute(
            builder: (context) => BlocProvider(
                  create: (_) => WalletDetailBloc(
                      networkInjector.I(), networkInjector.I(), injector()),
                  child:
                      WalletDetailPage(type: settings.arguments as CryptoType),
                ));
      case ReceivePage.tag:
        return CupertinoPageRoute(
            builder: (context) =>
                ReceivePage(payload: settings.arguments as WalletPayload));
      case SendCryptoPage.tag:
        return CupertinoPageRoute(
            builder: (context) => BlocProvider(
                  create: (_) => SendCryptoBloc(
                      networkInjector.I(),
                      networkInjector.I(),
                      injector(),
                      (settings.arguments as SendData).type),
                  child: SendCryptoPage(data: settings.arguments as SendData),
                ));
      case SendReviewPage.tag:
        return CupertinoPageRoute(
            builder: (context) => SendReviewPage(
                  payload: settings.arguments as SendCryptoPayload,
                ));
      case ArtworkPreviewPage.tag:
        return CupertinoPageRoute(
            builder: (context) => BlocProvider(
                  create: (_) => ArtworkPreviewBloc(
                      networkInjector.I<AppDatabase>().assetDao),
                  child: ArtworkPreviewPage(
                    payload: settings.arguments as ArtworkDetailPayload,
                  ),
                ));
      case SelectNetworkPage.tag:
        return CupertinoPageRoute(
            builder: (context) => BlocProvider(
                  create: (_) => SelectNetworkBloc(injector()),
                  child: SelectNetworkPage(),
                ));
      case ArtworkDetailPage.tag:
        return CupertinoPageRoute(
            builder: (context) => BlocProvider(
                  create: (_) => ArtworkDetailBloc(networkInjector.I(),
                      networkInjector.I<AppDatabase>().assetDao),
                  child: ArtworkDetailPage(
                      payload: settings.arguments as ArtworkDetailPayload),
                ));
      case TBConnectPage.tag:
        return MaterialPageRoute(
          builder: (context) =>
              TBConnectPage(request: settings.arguments as BeaconRequest),
        );
      case TBSignMessagePage.tag:
        return MaterialPageRoute(
          builder: (context) =>
              TBSignMessagePage(request: settings.arguments as BeaconRequest),
        );
      case TBSendTransactionPage.tag:
        return MaterialPageRoute(
          builder: (context) => TBSendTransactionPage(
              request: settings.arguments as BeaconRequest),
        );
      default:
        return CupertinoPageRoute(
            builder: (context) => BlocProvider(
                create: (_) => RouterBloc(injector<CloudDatabase>()),
                child: OnboardingPage()));
    }
  }
}
