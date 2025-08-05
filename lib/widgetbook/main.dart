import 'dart:async';

import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/widgetbook/mock/mock_injector.dart';
import 'package:autonomy_flutter/widgetbook/screens/mobile_controller_home_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import './main.directories.g.dart';

void main() {
  runZonedGuarded(() async {
    await dotenv.load();

    await MockInjector.setup();
    try {
      await MockDataSetup.setup();
    } catch (e, stackTrace) {
      log.info('Error setting up mock data: $e');
      log.info('Stack trace: $stackTrace');
      // Optionally rethrow or handle the error
    }
    await Future.delayed(const Duration(seconds: 1));
    await EasyLocalization.ensureInitialized();
    runApp(EasyLocalization(
      child: const WidgetbookApp(),
      supportedLocales: const [Locale('en', 'US'), Locale('ja')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      useFallbackTranslations: true,
    ));
  }, (error, stackTrace) {
    // Handle errors in the widgetbook
    log.info('Error in Widgetbook: $error');
    log.info('Stack trace: $stackTrace');
  });
}

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final figmaDevice = DeviceInfo.genericPhone(
            platform: TargetPlatform.iOS,
            id: 'Figma Device',
            name: 'Figma Device',
            screenSize: const Size(383, 852));
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: MockInjector.get<CanvasDeviceBloc>()),
            BlocProvider<AccountsBloc>(
              create: (context) => MockInjector.get<AccountsBloc>(),
            ),
          ],
          child: Widgetbook.material(
            lightTheme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.dark,
            home: Container(
              color: Colors.white,
              child: const Center(
                child: Text('Widgetbook Home Screen'),
              ),
            ),
            addons: [
              //DeviceFrameAddon should be used before all other addons.
              DeviceFrameAddon(
                devices: [
                  ...Devices.all,
                  // custom device
                  figmaDevice,
                ],
                initialDevice: figmaDevice,
              ),
              // ViewportAddon(Viewports.all),
              // InspectorAddon(
              //   enabled: true,
              // ),
              GridAddon(10),
              AlignmentAddon(),
              TextScaleAddon(),
              MaterialThemeAddon(themes: [
                // WidgetbookTheme(
                //   name: 'Light Theme',
                //   data: ThemeData.light(),
                // ),
                WidgetbookTheme(
                  name: 'Dark Theme',
                  data: ThemeData.dark(),
                ),
              ]),
              LocalizationAddon(
                locales: const [
                  Locale('en', 'US'),
                ],
                initialLocale: const Locale('en', 'US'),
                localizationsDelegates: [
                  ...context.localizationDelegates,
                ],
              ),
            ],
            directories: [
              ...directories,
              WidgetbookFolder(
                name: 'Screens',
                children: [
                  WidgetbookFolder(name: 'Home Page', children: [
                    mobileControllerHomePageComponent,
                  ])
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
