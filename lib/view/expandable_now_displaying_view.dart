import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/device_setting/bluetooth_connected_device_config.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart'; // Added for AppColor
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

ValueNotifier<bool> isNowDisplayingExpanded = ValueNotifier(false);

class ExpandableNowDisplayingView extends StatefulWidget {
  // final Widget Function(BuildContext) thumbnailBuilder;
  // final Widget Function(BuildContext) titleBuilder;
  // final BaseDevice? device;
  // final List<Widget> customAction;
  final List<OptionItem>? _options;
  final Widget Function(Function onMoreTap, bool isExpanded) headerBuilder;

  const ExpandableNowDisplayingView({
    required this.headerBuilder,
    super.key,
    List<OptionItem>? options,
  }) : this._options = options;

  List<OptionItem> get options => _options ?? _defaultOptions;

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
        },
      ),
      if (injector<AuthService>().isBetaTester() &&
          BluetoothDeviceManager().castingBluetoothDevice != null)
        // FF-X1 Setting
        OptionItem(
          title: 'FF1 Settings',
          icon: SvgPicture.asset('assets/images/portal_setting.svg'),
          onTap: () {
            injector<NavigationService>().navigateTo(
                AppRouter.bluetoothConnectedDeviceConfig,
                arguments: BluetoothConnectedDeviceConfigPayload());
          },
        ),
      // account
      OptionItem(
        title: 'wallet'.tr(),
        icon: const Icon(
          AuIcon.wallet,
        ),
        onTap: () {
          injector<NavigationService>().navigateTo(AppRouter.walletPage);
        },
      ),
      OptionItem(
        title: 'App Settings',
        icon: const Icon(
          AuIcon.settings,
        ),
        onTap: () {
          injector<NavigationService>().navigateTo(AppRouter.settingsPage);
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
        },
      ),
    ];
  }

  @override
  State<ExpandableNowDisplayingView> createState() =>
      _ExpandableNowDisplayingViewState();
}

class _ExpandableNowDisplayingViewState
    extends State<ExpandableNowDisplayingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _heightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final divider = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: addOnlyDivider(color: AppColor.auLightGrey),
    );
    return ValueListenableBuilder(
        valueListenable: isNowDisplayingExpanded,
        builder: (context, value, child) {
          // Start animation when expanded state changes
          if (value) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }

          return Container(
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.headerBuilder(() {
                  setState(() {
                    isNowDisplayingExpanded.value = !value;
                  });
                }, isNowDisplayingExpanded.value),
                divider,
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeInOut,
                      height: _heightAnimation.value *
                          (widget.options.length *
                              56.0), // Approximate height for each option
                      child: SingleChildScrollView(
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: value
                              ? ListView.separated(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final option = widget.options[index];
                                    if (option.builder != null) {
                                      return option.builder!
                                          .call(context, option);
                                    }
                                    return DrawerItem(
                                      item: option,
                                      color: AppColor.primaryBlack,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16.0,
                                        horizontal: 10.0,
                                      ),
                                    );
                                  },
                                  itemCount: widget.options.length,
                                  separatorBuilder: (context, index) => divider,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        });
  }
}
