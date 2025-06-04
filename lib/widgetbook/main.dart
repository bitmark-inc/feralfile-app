import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/widgetbook/mock/mock_injector.dart';
import 'package:autonomy_flutter/widgetbook/screens/daily_work_page.dart';
import 'package:autonomy_flutter/widgetbook/screens/feralfile/alumni/alumni_card.dart';
import 'package:autonomy_flutter/widgetbook/screens/feralfile/alumni/list_alumni_view.dart';
import 'package:autonomy_flutter/widgetbook/screens/feralfile/artwork_view.dart';
import 'package:autonomy_flutter/widgetbook/screens/feralfile/exhibition/exhibition_card.dart';
import 'package:autonomy_flutter/widgetbook/screens/feralfile/exhibition/list_exhibition_view.dart';
import 'package:autonomy_flutter/widgetbook/screens/feralfile/explore_search_bar.dart';
import 'package:autonomy_flutter/widgetbook/screens/feralfile/featured_work/featured_work_card.dart';
import 'package:autonomy_flutter/widgetbook/screens/feralfile/featured_work/featured_work_view.dart';
import 'package:autonomy_flutter/widgetbook/screens/feralfile/filter_bar.dart';
import 'package:autonomy_flutter/widgetbook/screens/feralfile/filter_expanded_item.dart';
import 'package:autonomy_flutter/widgetbook/screens/feralfile/sort_bar.dart';
import 'package:autonomy_flutter/widgetbook/screens/feralfile_home_page.dart';
import 'package:autonomy_flutter/widgetbook/screens/organize_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

void main() {
  MockInjector.setup();
  runApp(const WidgetbookApp());
}

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
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
            // WidgetbookTheme(
            //   name: 'Light Theme',
            //   data: ThemeData.light(),
            // ),
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
              // WidgetbookFolder(name: 'Common', children: [
              //   headerViewComponent,
              //   loadingWidgetComponent,
              //   backAppBarComponent,
              //   accountItemComponent,
              //   primaryButtonComponent,
              // ]),
              WidgetbookFolder(name: 'Feralfile', children: [
                exhibitionView(),
                seriesView(),
                exploreSearchBar(),
                featuredWorkCard(),
                featuredWorkView(),
                filterBar(),
                filterExpandedItem(),
                alumniCardView(),
                listAlumniView(),
                listExhibitionView(),
                sortBar(),
              ]),
            ],
          ),
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
      ),
    );
  }
}
