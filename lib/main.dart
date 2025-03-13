//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: unawaited_futures, type_annotate_public_apis
// ignore_for_file: avoid_annotating_with_dynamic

import 'dart:async';
import 'dart:ui';

import 'package:autonomy_flutter/common/database.dart';
import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/announcement/announcement_adapter.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/service/home_widget_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/au_file_service.dart';
import 'package:autonomy_flutter/util/canvas_device_adapter.dart';
import 'package:autonomy_flutter/util/custom_route_observer.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/now_displaying_view.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:floor/floor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:multi_value_listenable_builder/multi_value_listenable_builder.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:system_date_time_format/system_date_time_format.dart';
import 'package:workmanager/workmanager.dart';

const dailyWidgetTaskUniqueName =
    'feralfile.workmanager.iOSBackgroundAppRefresh';
const dailyWidgetTaskName = 'updateDailyWidgetData';
const dailyWidgetTaskTag = 'updateDailyWidgetDataTag';

@pragma('vm:entry-point')
Future<void> callbackDispatcher() async {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == dailyWidgetTaskUniqueName || task == dailyWidgetTaskName) {
        await dotenv.load();
        await setupHomeWidgetInjector();
        await injector<HomeWidgetService>().updateDailyTokensToHomeWidget();
      }
    } catch (e) {
      if (kDebugMode) {
        print('callbackDispatcher error: $e');
      }
      throw Exception(e);
    }

    return Future.value(true);
  });
}

ValueNotifier<bool> shouldShowNowDisplaying = ValueNotifier<bool>(false);
ValueNotifier<bool> shouldShowNowDisplayingOnDisconnect =
    ValueNotifier<bool>(true);

void main() async {
  unawaited(
    runZonedGuarded(() async {
      await dotenv.load();
      await SentryFlutter.init(
        (options) {
          options
            ..dsn = Environment.sentryDSN
            ..enableAutoSessionTracking = true
            ..tracesSampleRate = 0.25
            ..attachStacktrace = true
            ..beforeSend = (SentryEvent event, Hint hint) {
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
    }),
  );
}

Future<void> runFeralFileApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  // feature/text_localization
  await EasyLocalization.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await FlutterDownloader.initialize();
  await Hive.initFlutter();
  _registerHiveAdapter();
  ObjectBox.create();

  FlutterDownloader.registerCallback(downloadCallback);
  try {
    await AuFileService().setup();
  } catch (e) {
    log.info('Error in AuFileService setup: $e');
  }

  OneSignal.initialize(Environment.onesignalAppID);
  OneSignal.Debug.setLogLevel(OSLogLevel.error);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColor.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    showErrorDialogFromException(
      details.exception,
      stackTrace: details.stack,
      library: details.library,
    );
  };

  await _setupApp();
}

void _registerHiveAdapter() {
  Hive
    ..registerAdapter(CanvasDeviceAdapter())
    ..registerAdapter(AnnouncementLocalAdapter());
}

Future<void> _setupWorkManager() async {
  try {
    await Workmanager().initialize(callbackDispatcher);
    Workmanager()
        .cancelByTag(dailyWidgetTaskTag)
        .catchError((Object e) => log.info('Error in cancelTaskByTag: $e'));
    await _startBackgroundUpdate();
  } catch (e) {
    log.info('Error in _setupWorkManager: $e');
  }
}

Future<void> _startBackgroundUpdate() async {
  await Workmanager().registerPeriodicTask(
    dailyWidgetTaskUniqueName,
    dailyWidgetTaskName,
    tag: dailyWidgetTaskTag,
    frequency: const Duration(hours: 4),
    existingWorkPolicy: ExistingWorkPolicy.replace,
    constraints: Constraints(networkType: NetworkType.connected),
  );
}

Future<void> _connectToBluetoothDevice() async {
  try {
    final bluetoothDevice =
        injector<FFBluetoothService>().castingBluetoothDevice;
    if (bluetoothDevice != null) {
      await injector<FFBluetoothService>().connectToDevice(bluetoothDevice,
          shouldShowError: false, shouldChangeNowDisplayingStatus: true);
    }
  } catch (e) {
    log.info('Error in connecting to connected device: $e');
  }
}

Future<void> _setupApp() async {
  try {
    await setupLogger();
  } catch (e) {
    log.info('Error in setupLogger: $e');
    Sentry.captureException(e);
  }
  await setupInjector();
  unawaited(_setupWorkManager());
  unawaited(_connectToBluetoothDevice());
  runApp(
    SDTFScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('en', 'US'), Locale('ja')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en', 'US'),
        useFallbackTranslations: true,
        child: const OverlaySupport.global(
          child: AutonomyApp(),
        ),
      ),
    ),
  );

  Sentry.configureScope((scope) async {
    final deviceID = await getDeviceID();
    scope.setUser(SentryUser(id: deviceID));
  });
}

Future<void> _deleteLocalDatabase() async {
  final appDatabaseMainnet =
      await sqfliteDatabaseFactory.getDatabasePath('app_database_mainnet.db');
  final appDatabaseTestnet =
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
              HeroController(),
            ],
            initialRoute: AppRouter.onboardingPage,
            onGenerateRoute: AppRouter.onGenerateRoute,
            builder: (context, child) {
              return MultiValueListenableBuilder(
                valueListenables: [
                  shouldShowNowDisplaying,
                  shouldShowNowDisplayingOnDisconnect
                ],
                child: child,
                builder: (context, values, c) {
                  final hasDevice =
                      injector<FFBluetoothService>().castingBluetoothDevice !=
                          null;
                  final value = (values[0] as bool) && (values[1] as bool);
                  log.info('shouldShowNowDisplaying: $value');

                  if (!value ||
                      !hasDevice ||
                      !injector<AuthService>().isBetaTester()) {
                    return c!;
                  }
                  return Scaffold(
                    backgroundColor: AppColor.primaryBlack,
                    appBar: getDarkEmptyAppBar(),
                    body: SafeArea(
                      child: Column(
                        children: [
                          AnimatedSwitcher(
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            duration: const Duration(milliseconds: 1000),
                            child: NowDisplaying(
                              key: GlobalKey(),
                            ),
                          ),
                          Expanded(
                            child: c!,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      );
}

final RouteObserver<ModalRoute<void>> routeObserver =
    CustomRouteObserver<ModalRoute<void>>();

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final send = IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}
