import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/screen/account/accounts_preview_page.dart';
import 'package:autonomy_flutter/screen/account/add_account_page.dart';
import 'package:autonomy_flutter/screen/account/import_account_page.dart';
import 'package:autonomy_flutter/screen/account/link_account_page.dart';
import 'package:autonomy_flutter/screen/account/link_feralfile_page.dart';
import 'package:autonomy_flutter/screen/account/link_wallet_connect_page.dart';
import 'package:autonomy_flutter/screen/account/linked_account_details_page.dart';
import 'package:autonomy_flutter/screen/account/name_linked_account_page.dart';
import 'package:autonomy_flutter/screen/account/name_persona_page.dart';
import 'package:autonomy_flutter/screen/account/new_account_page.dart';
import 'package:autonomy_flutter/screen/bloc/connections/connections_bloc.dart';
import 'package:autonomy_flutter/screen/cloud_page.dart';
import 'package:autonomy_flutter/screen/connection/connection_details_page.dart';
import 'package:autonomy_flutter/screen/connection/persona_connections_page.dart';
import 'package:autonomy_flutter/screen/account/persona_details_page.dart';
import 'package:autonomy_flutter/screen/account/recovery_phrase_page.dart';
import 'package:autonomy_flutter/screen/be_own_gallery_page.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/ethereum/ethereum_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/feralfile/feralfile_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/router/router_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/tezos/tezos_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_page.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_page.dart';
import 'package:autonomy_flutter/screen/onboarding_page.dart';
import 'package:autonomy_flutter/screen/report/sentry_report_page.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/receive_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_review_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_page.dart';
import 'package:autonomy_flutter/screen/settings/networks/select_network_bloc.dart';
import 'package:autonomy_flutter/screen/settings/networks/select_network_page.dart';
import 'package:autonomy_flutter/screen/settings/settings_page.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_sign_message_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_bloc.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_connect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_disconnect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_sign_message_page.dart';
import 'package:autonomy_flutter/util/tezos_beacon_channel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_connect/wallet_connect.dart';

import 'account/link_beacon_connect_page.dart';

class AppRouter {
  static const onboardingPage = "onboarding";
  static const beOwnGalleryPage = 'be_own_gallery';
  static const newAccountPage = "new_account";
  static const addAccountPage = 'add_account';
  static const linkAccountpage = "link_account";
  static const linkWalletConnectPage = "link_wallet_connect";
  static const linkBeaconConnectPage = "link_beacon_connect";
  static const accountsPreviewPage = 'accounts_preview';
  static const linkFeralFilePage = "link_feralfile";
  static const namePersonaPage = "name_persona_page";
  static const nameLinkedAccountPage = 'name_linked_account';
  static const importAccountPage = 'import_account';
  static const homePage = "home_page";
  static const homePageNoTransition = 'home_page_NoTransition';
  static const settingsPage = "settings";
  static const personaDetailsPage = "persona_details";
  static const personaConnectionsPage = "persona_connections";
  static const connectionDetailsPage = 'connection_details';
  static const linkedAccountDetailsPage = 'linked_account_details';
  static const walletDetailsPage = 'wallet_detail';
  static const scanQRPage = 'qr_scanner';
  static const recoveryPhrasePage = 'recovery_phrase';
  static const wcConnectPage = 'wc_connect';
  static const cloudPage = 'cloud_page';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final networkInjector = injector<NetworkConfigInjector>();

    final ethereumBloc = EthereumBloc(injector(), networkInjector.I());
    final tezosBloc = TezosBloc(injector(), networkInjector.I());
    final accountsBloc = AccountsBloc(injector(), injector<CloudDatabase>());

    switch (settings.name) {
      case onboardingPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                create: (_) =>
                    RouterBloc(injector(), injector<CloudDatabase>()),
                child: OnboardingPage()));

      case homePageNoTransition:
        return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animetion1, animation2) => BlocProvider(
                  create: (_) => HomeBloc(
                      networkInjector.I(),
                      injector(),
                      injector(),
                      networkInjector.I<AppDatabase>().assetDao,
                      networkInjector.I(),
                      injector<CloudDatabase>()),
                  child: HomePage(),
                ),
            transitionDuration: Duration(seconds: 0));

      case homePage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) => HomeBloc(
                      networkInjector.I(),
                      injector(),
                      injector(),
                      networkInjector.I<AppDatabase>().assetDao,
                      networkInjector.I(),
                      injector<CloudDatabase>()),
                  child: HomePage(),
                ));
      case beOwnGalleryPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => BeOwnGalleryPage(),
        );
      case AppRouter.newAccountPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                create: (_) => PersonaBloc(
                      injector<CloudDatabase>(),
                      injector(),
                      injector(),
                    ),
                child: NewAccountPage()));

      case addAccountPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                create: (_) => PersonaBloc(
                      injector<CloudDatabase>(),
                      injector(),
                      injector(),
                    ),
                child: AddAccountPage()));

      case AppRouter.linkAccountpage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider.value(
                value: accountsBloc, child: LinkAccountPage()));

      case accountsPreviewPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(providers: [
                  BlocProvider.value(value: accountsBloc),
                  BlocProvider(
                      create: (_) => PersonaBloc(
                            injector<CloudDatabase>(),
                            injector(),
                            injector(),
                          )),
                ], child: AccountsPreviewPage()));

      case linkFeralFilePage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                create: (_) => FeralfileBloc(
                    injector(), networkInjector.I(), injector<CloudDatabase>()),
                child: LinkFeralFilePage()));

      case linkBeaconConnectPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) =>
                LinkBeaconConnectPage(uri: settings.arguments as String));

      case linkWalletConnectPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider.value(
                value: accountsBloc,
                child: LinkWalletConnectPage(
                  unableOpenAppname: (settings.arguments as String?) ?? "",
                )));

      case AppRouter.namePersonaPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) => PersonaBloc(
                    injector<CloudDatabase>(),
                    injector(),
                    injector(),
                  ),
                  child: NamePersonaPage(uuid: settings.arguments as String),
                ));

      case AppRouter.nameLinkedAccountPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider.value(
                value: accountsBloc,
                child: NameLinkedAccountPage(
                    connection: settings.arguments as Connection)));

      case importAccountPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                create: (_) => PersonaBloc(
                      injector<CloudDatabase>(),
                      injector(),
                      injector(),
                    ),
                child: ImportAccountPage()));

      case wcConnectPage:
        final argument = settings.arguments;
        switch (argument.runtimeType) {
          case WCConnectPageArgs:
            return CupertinoPageRoute(
              settings: settings,
              builder: (context) => BlocProvider(
                  create: (_) => PersonaBloc(
                        injector<CloudDatabase>(),
                        injector(),
                        injector(),
                      ),
                  child: WCConnectPage(
                      wcConnectArgs: argument as WCConnectPageArgs,
                      beaconRequest: null)),
            );

          case BeaconRequest:
            return CupertinoPageRoute(
              settings: settings,
              builder: (context) => BlocProvider(
                  create: (_) => PersonaBloc(
                        injector<CloudDatabase>(),
                        injector(),
                        injector(),
                      ),
                  child: WCConnectPage(
                      wcConnectArgs: null,
                      beaconRequest: argument as BeaconRequest?)),
            );

          default:
            throw Exception('Invalid route: ${settings.name}');
        }

      case WCDisconnectPage.tag:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) =>
              WCDisconnectPage(client: settings.arguments as WCClient),
        );
      case WCSignMessagePage.tag:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => BlocProvider(
              create: (_) => FeralfileBloc(
                  injector(), networkInjector.I(), injector<CloudDatabase>()),
              child: WCSignMessagePage(
                  args: settings.arguments as WCSignMessagePageArgs)),
        );
      case WCSendTransactionPage.tag:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => BlocProvider(
            create: (_) => WCSendTransactionBloc(
                injector(), networkInjector.I(), injector(), injector()),
            child: WCSendTransactionPage(
                args: settings.arguments as WCSendTransactionPageArgs),
          ),
        );
      case ScanQRPage.tag:
        return CupertinoPageRoute(
            settings: settings,
            fullscreenDialog: true,
            builder: (context) => BlocProvider(
                create: (_) => FeralfileBloc(
                    injector(), networkInjector.I(), injector<CloudDatabase>()),
                child: ScanQRPage(
                    scannerItem: settings.arguments as ScannerItem)));
      case settingsPage:
        return CupertinoPageRoute(
            settings: settings,
            fullscreenDialog: true,
            builder: (context) => MultiBlocProvider(providers: [
                  BlocProvider.value(value: accountsBloc),
                  BlocProvider(
                      create: (_) => PersonaBloc(
                            injector<CloudDatabase>(),
                            injector(),
                            injector(),
                          )),
                  BlocProvider.value(value: ethereumBloc),
                  BlocProvider.value(value: tezosBloc),
                ], child: SettingsPage()));

      case personaDetailsPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: ethereumBloc),
                      BlocProvider.value(value: tezosBloc),
                    ],
                    child: PersonaDetailsPage(
                      persona: settings.arguments as Persona,
                    )));

      case personaConnectionsPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                create: (_) => ConnectionsBloc(
                      injector<CloudDatabase>(),
                      injector(),
                      injector(),
                    ),
                child: PersonaConnectionsPage(
                    payload: settings.arguments as PersonaConnectionsPayload)));

      case connectionDetailsPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                create: (_) => ConnectionsBloc(
                      injector<CloudDatabase>(),
                      injector(),
                      injector(),
                    ),
                child: ConnectionDetailsPage(
                  connectionItem: settings.arguments as ConnectionItem,
                )));

      case linkedAccountDetailsPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) => FeralfileBloc(injector(), networkInjector.I(),
                      injector<CloudDatabase>()),
                  child: LinkedAccountDetailsPage(
                      connection: settings.arguments as Connection),
                ));

      case walletDetailsPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) => WalletDetailBloc(
                      networkInjector.I(), networkInjector.I(), injector()),
                  child: WalletDetailPage(
                      payload: settings.arguments as WalletDetailsPayload),
                ));
      case ReceivePage.tag:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) =>
                ReceivePage(payload: settings.arguments as WalletPayload));
      case SendCryptoPage.tag:
        return CupertinoPageRoute(
            settings: settings,
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
            settings: settings,
            builder: (context) => SendReviewPage(
                  payload: settings.arguments as SendCryptoPayload,
                ));
      case ArtworkPreviewPage.tag:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) => ArtworkPreviewBloc(
                      networkInjector.I<AppDatabase>().assetDao),
                  child: ArtworkPreviewPage(
                    payload: settings.arguments as ArtworkDetailPayload,
                  ),
                ));
      case SelectNetworkPage.tag:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) => SelectNetworkBloc(injector()),
                  child: SelectNetworkPage(),
                ));
      case ArtworkDetailPage.tag:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) => ArtworkDetailBloc(networkInjector.I(),
                      networkInjector.I<AppDatabase>().assetDao),
                  child: ArtworkDetailPage(
                      payload: settings.arguments as ArtworkDetailPayload),
                ));
      case TBSignMessagePage.tag:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) =>
              TBSignMessagePage(request: settings.arguments as BeaconRequest),
        );
      case TBSendTransactionPage.tag:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => TBSendTransactionPage(
              request: settings.arguments as BeaconRequest),
        );

      case recoveryPhrasePage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => RecoveryPhrasePage(
                  words: settings.arguments as List<String>,
                ));

      case cloudPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => CloudPage(
                  section: settings.arguments as String,
                ));

      case SentryReportPage.tag:
        return CupertinoPageRoute(
            settings: settings,
            fullscreenDialog: true,
            builder: (context) => SentryReportPage(
                  payload: settings.arguments,
                ));
      default:
        throw Exception('Invalid route: ${settings.name}');
    }
  }
}
