import 'dart:io';

import 'package:autonomy_flutter/database/app_database.dart';
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
import 'package:autonomy_flutter/screen/tezos_beacon/tb_connect_page.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_sign_message_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_bloc.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_connect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_disconnect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_sign_message_page.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/persona_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/migration_util.dart';
import 'package:autonomy_flutter/util/tezos_beacon_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wallet_connect/wallet_connect.dart';

import 'common/injector.dart';
import 'common/network_config_injector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setup();

  await MigrationUtil().migrateIfNeeded();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://3327d497b7324d2e9824c88bec2235e2@o142150.ingest.sentry.io/6088804';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => BlocOverrides.runZoned(
      () => runApp(AutonomyApp()),
      blocObserver: AppBlocObserver(),
    ),
  );

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    log.severe("unhandled error: $details");
    // quit the app with error
    exit(1);
  };
}

class AutonomyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final networkInjector = injector<NetworkConfigInjector>();

    return CupertinoApp(
        title: 'Autonomy',
        theme: CupertinoThemeData(
          scaffoldBackgroundColor: Colors.white,
          primaryColor: Colors.grey,
          barBackgroundColor: Color(0xFF6D6B6B),
          // errorColor: Color(0xFFA1200A),
          textTheme: CupertinoTextThemeData(
            primaryColor: Colors.grey,
          ),
        ),
        localizationsDelegates: [
          DefaultMaterialLocalizations.delegate,
          DefaultCupertinoLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        debugShowCheckedModeBanner: false,
        navigatorKey: injector<NavigationService>().navigatorKey,
        navigatorObservers: [routeObserver],
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case HomePage.tag:
              return CupertinoPageRoute(
                  builder: (context) => BlocProvider(
                        create: (_) => HomeBloc(
                            networkInjector.I(),
                            injector(),
                            injector(),
                            networkInjector.I<AppDatabase>().assetDao),
                        child: HomePage(),
                      ));
            case WCConnectPage.tag:
              return CupertinoPageRoute(
                builder: (context) => WCConnectPage(
                    args: settings.arguments as WCConnectPageArgs),
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
                        create: (_) => WalletDetailBloc(networkInjector.I(),
                            networkInjector.I(), injector()),
                        child: WalletDetailPage(
                            type: settings.arguments as CryptoType),
                      ));
            case ReceivePage.tag:
              return CupertinoPageRoute(
                  builder: (context) => ReceivePage(
                      payload: settings.arguments as WalletPayload));
            case SendCryptoPage.tag:
              return CupertinoPageRoute(
                  builder: (context) => BlocProvider(
                        create: (_) => SendCryptoBloc(
                            networkInjector.I(),
                            networkInjector.I(),
                            injector(),
                            (settings.arguments as SendData).type),
                        child: SendCryptoPage(
                            data: settings.arguments as SendData),
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
                            payload:
                                settings.arguments as ArtworkDetailPayload),
                      ));
            case TBConnectPage.tag:
              return MaterialPageRoute(
                builder: (context) =>
                    TBConnectPage(request: settings.arguments as BeaconRequest),
              );
            case TBSignMessagePage.tag:
              return MaterialPageRoute(
                builder: (context) => TBSignMessagePage(
                    request: settings.arguments as BeaconRequest),
              );
            case TBSendTransactionPage.tag:
              return MaterialPageRoute(
                builder: (context) => TBSendTransactionPage(
                    request: settings.arguments as BeaconRequest),
              );
            default:
              if (injector<PersonaService>().getActivePersona() == null) {
                return CupertinoPageRoute(
                    builder: (context) => OnboardingPage());
              } else {
                return CupertinoPageRoute(
                    builder: (context) => BlocProvider(
                          create: (_) => HomeBloc(
                              networkInjector.I(),
                              injector(),
                              injector(),
                              networkInjector.I<AppDatabase>().assetDao),
                          child: HomePage(),
                        ));
              }
          }
        });
  }
}

/// Custom [BlocObserver] that observes all bloc and cubit state changes.
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (bloc is Cubit) print(change);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    log.info(transition);
  }
}

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
