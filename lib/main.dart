import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/migration_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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
      initialRoute: AppRouter.onboardingPage,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
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
