import 'package:autonomy_flutter/widgetbook/components/header_view.dart';
import 'package:autonomy_flutter/widgetbook/components/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:widgetbook_workspace/components/account_view.dart';
import 'package:widgetbook_workspace/components/app_bar/back_app_bar.dart';
import 'package:widgetbook_workspace/components/primary_button_component.dart';
import 'package:widgetbook_workspace/screens/home/home_navigation_page_component.dart';
import 'package:widgetbook_workspace/screens/settings/settings_page_component.dart';
import 'package:widgetbook_workspace/screens/wallet/components/accounts_view.dart';
import 'package:widgetbook_workspace/screens/wallet/components/address_card.dart';
import 'package:widgetbook_workspace/screens/wallet/components/edit_account_item.dart';
import 'package:widgetbook_workspace/screens/wallet/components/empty_address_list.dart';
import 'package:widgetbook_workspace/screens/wallet/components/no_edit_addresses_list.dart';
import 'package:widgetbook_workspace/screens/wallet/components/recovery_phrase_warning.dart';
import 'package:widgetbook_workspace/screens/wallet/components/reorderable_addresses_list.dart';
import 'package:widgetbook_workspace/screens/wallet/components/view_address_item.dart';
import 'package:widgetbook_workspace/screens/wallet/components/wallet_app_bar.dart';
import 'package:widgetbook_workspace/stories/wallet_page.stories.dart';

void main() {
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
        WidgetbookFolder(
          name: 'Components',
          children: [
            headerViewComponent,
            loadingWidgetComponent,
            backAppBarComponent,
            accountItemComponent,
            primaryButtonComponent,
          ],
        ),
        WidgetbookFolder(
          name: 'Screens',
          children: [
            WidgetbookFolder(
              name: 'Wallet',
              children: [
                WalletPageComponent(),
                RecoveryPhraseWarningComponent(),
                WalletAppBarComponent(),
                AccountsViewComponent(),
                EmptyAddressListComponent(),
                NoEditAddressesListComponent(),
                ReorderableAddressesListComponent(),
                ViewAddressItemComponent(),
                EditAccountItemComponent(),
                AddressCardComponent(),
              ],
            ),
            WidgetbookFolder(
              name: 'Account',
              children: [
                settingsPageComponent,
              ],
            ),
            WidgetbookFolder(
              name: 'Account View',
              children: [homeNavigationPageComponent],
            ),
          ],
        ),
      ],
    );
  }
}
