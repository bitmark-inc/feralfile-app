import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/device_setting/bluetooth_connected_device_config.dart';
import 'package:autonomy_flutter/screen/mobile_controller/constants/ui_constants.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/channels/channels_page.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/playlists/playlists_page.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/works/works_page.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/header.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/expandable_now_displaying_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ListDirectoryPage extends StatefulWidget {
  const ListDirectoryPage({super.key});

  @override
  State<ListDirectoryPage> createState() => _ListDirectoryPageState();
}

class _ListDirectoryPageState extends State<ListDirectoryPage>
    with AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  int _selectedPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final pages = [
      const PlaylistsPage(),
      const ChannelsPage(),
      const WorksPage(),
    ];
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          SizedBox(
            height: 154,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    // Handle back button tap
                    UIHelper.showCenterMenu(context, options: _defaultOptions);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 15, top: 16),
                    child: SvgPicture.asset(
                      'assets/images/icon_drawer.svg',
                      width: 22,
                      colorFilter: const ColorFilter.mode(
                        AppColor.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          HeaderWidget(
            selectedIndex: _selectedPageIndex,
            onPageChanged: (index) {
              setState(() {
                _selectedPageIndex = index;
              });
              _pageController.jumpToPage(index);
            },
          ),
          const SizedBox(height: UIConstants.detailPageHeaderPadding),
          // _myCollectionButton(context),
          Expanded(
            child: PageView.builder(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return pages[index];
              },
            ),
          ),
        ],
      ),
    );
  }

  List<OptionItem> get _defaultOptions {
    return [
      // scan
      OptionItem(
        title: 'scan'.tr(),
        icon: const Icon(
          AuIcon.scan,
        ),
        onTap: () {
          injector<NavigationService>().navigateTo(
            AppRouter.scanQRPage,
            arguments: const ScanQRPagePayload(scannerItem: ScannerItem.GLOBAL),
          );
          isNowDisplayingExpanded.value = false;
        },
      ),
      if (injector<AuthService>().isBetaTester() &&
          BluetoothDeviceManager().castingBluetoothDevice != null)
        // FF-X1 Setting
        OptionItem(
          title: 'FF1 Settings',
          icon: SvgPicture.asset(
            'assets/images/portal_setting.svg',
            colorFilter: ColorFilter.mode(AppColor.white, BlendMode.srcIn),
          ),
          onTap: () {
            injector<NavigationService>().navigateTo(
                AppRouter.bluetoothConnectedDeviceConfig,
                arguments: BluetoothConnectedDeviceConfigPayload());
            isNowDisplayingExpanded.value = false;
          },
        ),
      OptionItem(
        title: 'App Settings',
        icon: const Icon(
          AuIcon.settings,
        ),
        onTap: () {
          injector<NavigationService>().navigateTo(AppRouter.settingsPage);
          isNowDisplayingExpanded.value = false;
        },
      ),
      // help
      OptionItem(
        title: 'help'.tr(),
        icon: ValueListenableBuilder<List<int>?>(
          valueListenable:
              injector<CustomerSupportService>().numberOfIssuesInfo,
          builder: (
            BuildContext context,
            List<int>? numberOfIssuesInfo,
            Widget? child,
          ) =>
              iconWithRedDot(
            icon: const Icon(
              AuIcon.help,
            ),
            padding: const EdgeInsets.only(right: 2, top: 2),
            withReddot: numberOfIssuesInfo != null && numberOfIssuesInfo[1] > 0,
          ),
        ),
        onTap: () {
          injector<NavigationService>()
              .navigateTo(AppRouter.supportCustomerPage);
          isNowDisplayingExpanded.value = false;
        },
      ),
    ];
  }

  @override
  bool get wantKeepAlive => true;
}
