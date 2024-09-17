//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: unawaited_futures, type_annotate_public_apis
// ignore_for_file: avoid_annotating_with_dynamic

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/encrypt_env/secrets.dart';
import 'package:autonomy_flutter/encrypt_env/secrets.g.dart';
import 'package:autonomy_flutter/model/announcement/announcement_adapter.dart';
import 'package:autonomy_flutter/model/eth_pending_tx_amount.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/deeplink_service.dart';
import 'package:autonomy_flutter/service/device_info_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/notification_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/util/au_file_service.dart';
import 'package:autonomy_flutter/util/canvas_device_adapter.dart';
import 'package:autonomy_flutter/util/custom_route_observer.dart';
import 'package:autonomy_flutter/util/dailies_helper.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/john_gerrard_helper.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:floor/floor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  unawaited(runZonedGuarded(() async {
    final json = await getSecretEnv();
    cachedSecretEnv = jsonDecode(json);
    await dotenv.load();
    await SentryFlutter.init(
      (options) {
        options
          ..dsn = Environment.sentryDSN
          ..enableAutoSessionTracking = true
          ..tracesSampleRate = 0.25
          ..attachStacktrace = true
          ..beforeSend = (SentryEvent event, {dynamic hint}) {
            // Avoid sending events with "level": "debug"
            if (event.level == SentryLevel.debug) {
              // Return null to drop the event
              return null;
            }
            return event;
          };
      },
      appRunner: () async {
        try {
          await runFeralFileApp();
        } catch (e, stackTrace) {
          await Sentry.captureException(e, stackTrace: stackTrace);
          rethrow;
        }
      },
    );
  }, (Object error, StackTrace stackTrace) async {
    /// Check error is Database issue
    if (error.toString().contains('DatabaseException')) {
      log.info('[DatabaseException] Remove local database and resume app');

      await _deleteLocalDatabase();

      /// Need to setup app again
      Future.delayed(const Duration(milliseconds: 200), () async {
        await _setupApp();
      });
    } else {
      showErrorDialogFromException(error, stackTrace: stackTrace);
    }
  }));
}

Future<void> runFeralFileApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  // feature/text_localization
  await EasyLocalization.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await FlutterDownloader.initialize();
  await Hive.initFlutter();
  _registerHiveAdapter();

  FlutterDownloader.registerCallback(downloadCallback);
  await AuFileService().setup();

  OneSignal.shared.setLogLevel(OSLogLevel.error, OSLogLevel.none);
  OneSignal.shared.setAppId(Environment.onesignalAppID);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: AppColor.white,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    showErrorDialogFromException(details.exception,
        stackTrace: details.stack, library: details.library);
  };

  await _setupApp();
}

void _registerHiveAdapter() {
  Hive
    ..registerAdapter(EthereumPendingTxAmountAdapter())
    ..registerAdapter(EthereumPendingTxListAdapter())
    ..registerAdapter(CanvasDeviceAdapter())
    ..registerAdapter(AnnouncementLocalAdapter());
}

Future<void> _setupApp() async {
  await setup();

  await DeviceInfo.instance.init();

  await injector<DeviceInfoService>().init();
  final metricClient = injector.get<MetricClientService>();
  await metricClient.initService();
  await injector<RemoteConfigService>().loadConfigs();

  final countOpenApp = injector<ConfigurationService>().countOpenApp() ?? 0;
  injector<ConfigurationService>().setCountOpenApp(countOpenApp + 1);
  final packageInfo = await PackageInfo.fromPlatform();
  await injector<ConfigurationService>().setVersionInfo(packageInfo.version);
  final notificationService = injector<NotificationService>();
  await notificationService.initNotification();
  await notificationService.startListeningNotificationEvents();
  await disableLandscapeMode();
  final isPremium = await injector.get<IAPService>().isSubscribed();
  await injector<ConfigurationService>().setPremium(isPremium);
  await JohnGerrardHelper.updateJohnGerrardLatestRevealIndex();
  DailiesHelper.updateDailies([]);
  // since we postpone handling deeplink until home, we don't need to delay this
  await injector<DeeplinkService>().setup();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('vi'), Locale('ja')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      child: const OverlaySupport.global(
        child: AutonomyApp(),
      ),
    ),
  );

  Sentry.configureScope((scope) async {
    final deviceID = await getDeviceID();
    scope.setUser(SentryUser(id: deviceID));
  });
}

Future<void> _deleteLocalDatabase() async {
  String appDatabaseMainnet =
      await sqfliteDatabaseFactory.getDatabasePath('app_database_mainnet.db');
  String appDatabaseTestnet =
      await sqfliteDatabaseFactory.getDatabasePath('app_database_testnet.db');
  await sqfliteDatabaseFactory.deleteDatabase(appDatabaseMainnet);
  await sqfliteDatabaseFactory.deleteDatabase(appDatabaseTestnet);
}

class AutonomyApp extends StatelessWidget {
  const AutonomyApp({super.key});

  static double maxWidth = 0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          maxWidth = constraints.maxWidth;
          return MaterialApp(
            title: 'Autonomy',
            theme: ResponsiveLayout.isMobile
                ? AppTheme.lightTheme()
                : AppTheme.tabletLightTheme(),
            darkTheme: AppTheme.lightTheme(),
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            debugShowCheckedModeBanner: false,
            navigatorKey: injector<NavigationService>().navigatorKey,
            navigatorObservers: [
              routeObserver,
              SentryNavigatorObserver(),
              HeroController()
            ],
            initialRoute: AppRouter.onboardingPage,
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      );
}

final RouteObserver<ModalRoute<void>> routeObserver =
    CustomRouteObserver<ModalRoute<void>>();

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send =
      IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}
