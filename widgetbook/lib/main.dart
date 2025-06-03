import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:widgetbook_workspace/mock/mock_injector.dart';
import 'package:widgetbook_workspace/screens/daily_work_page.dart';
import 'package:widgetbook_workspace/screens/feralfile_home_page.dart';
import 'package:widgetbook_workspace/screens/organize_home_page.dart';

void main() {
  MockInjector.setup();
  runApp(const WidgetbookApp());
}

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
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
          ],
          initialDevice: Devices.android.pixel4,
        ),
        // ViewportAddon(Viewports.all),
        InspectorAddon(
          enabled: true,
        ),
        GridAddon(10),
        AlignmentAddon(),
        TextScaleAddon(),
        MaterialThemeAddon(themes: [
          WidgetbookTheme(
            name: 'Light Theme',
            data: ThemeData.light(),
          ),
          WidgetbookTheme(
            name: 'Dark Theme',
            data: ThemeData.dark(),
          ),
        ]),
      ],
      directories: [
        // WidgetbookFolder(
        //   name: 'Components',
        //   children: [
        //     headerViewComponent,
        //     loadingWidgetComponent,
        //     backAppBarComponent,
        //     accountItemComponent,
        //     primaryButtonComponent,
        //   ],
        // ),
        WidgetbookFolder(
          name: 'Screens',
          children: [
            // WidgetbookFolder(
            //   name: 'Wallet',
            //   children: [
            //     WalletPageComponent(),
            //     RecoveryPhraseWarningComponent(),
            //     WalletAppBarComponent(),
            //     AccountsViewComponent(),
            //     EmptyAddressListComponent(),
            //     NoEditAddressesListComponent(),
            //     ReorderableAddressesListComponent(),
            //     ViewAddressItemComponent(),
            //     EditAccountItemComponent(),
            //     AddressCardComponent(),
            //   ],
            // ),
            // WidgetbookFolder(
            //   name: 'Account',
            //   children: [
            //     settingsPageComponent,
            //   ],
            // ),
            // WidgetbookFolder(
            //   name: 'Account View',
            //   children: [homeNavigationPageComponent],
            // ),
            WidgetbookComponent(
              name: 'Daily Work Page',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => const DailyWorkPageComponent(),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Feralfile Home Page',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => const FeralfileHomePageComponent(),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Organize Home Page',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => const OrganizeHomePageComponent(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
