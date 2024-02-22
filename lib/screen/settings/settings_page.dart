//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/cloud/cloud_android_page.dart';
import 'package:autonomy_flutter/screen/cloud/cloud_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/helpers.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/version_check.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/external_app_info_view.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with RouteAware, WidgetsBindingObserver, TickerProviderStateMixin {
  PackageInfo? _packageInfo;
  VersionCheck? _versionCheck;
  late ScrollController _controller;
  int _lastTap = 0;
  int _consecutiveTaps = 0;

  final GlobalKey<State> _preferenceKey = GlobalKey();
  bool _pendingSettingsCleared = false;
  final _settingsDataServices = injector<SettingsDataService>();
  final _versionService = injector<VersionService>();
  final _configurationService = injector<ConfigurationService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadPackageInfo());
    unawaited(_checkVersion());
    unawaited(_settingsDataServices.backup());
    unawaited(_versionService.checkForUpdate());
    _controller = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
    ));
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
    ));
    unawaited(injector<SettingsDataService>().backup());
  }

  Widget _settingItem({
    required String title,
    required Widget icon,
    required Function() onTap,
    Widget? stateWidget,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0),
      child: TappableForwardRow(
        leftWidget: Row(
          children: [
            icon,
            const SizedBox(width: 32),
            Text(
              title,
              style: theme.textTheme.ppMori400Black16,
            ),
            const Spacer(),
            if (stateWidget != null) stateWidget,
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: getBackAppBar(
          context,
          title: 'settings'.tr(),
          onBack: () {
            Navigator.of(context).pop();
          },
        ),
        body: SafeArea(
          child: NotificationListener(
            child: Column(
              children: [
                const SizedBox(height: 30),
                Column(
                  children: [
                    _settingItem(
                      title: 'preferences'.tr(),
                      icon: const Icon(AuIcon.preferences),
                      onTap: () async {
                        await Navigator.of(context)
                            .pushNamed(AppRouter.preferencesPage);
                      },
                    ),
                    addOnlyDivider(),
                    _settingItem(
                      title: 'back_up'.tr(),
                      icon: SvgPicture.asset('assets/images/icon_backup.svg'),
                      onTap: () async {
                        if (Platform.isAndroid) {
                          final isAndroidEndToEndEncryptionAvailable =
                              await injector<AccountService>()
                                  .isAndroidEndToEndEncryptionAvailable();
                          if (!mounted) {
                            return;
                          }
                          await Navigator.of(context).pushNamed(
                              AppRouter.cloudAndroidPage,
                              arguments: CloudAndroidPagePayload(
                                  isEncryptionAvailable:
                                      isAndroidEndToEndEncryptionAvailable));
                        } else {
                          await Navigator.of(context).pushNamed(
                              AppRouter.cloudPage,
                              arguments:
                                  CloudPagePayload(section: 'nameAlias'));
                        }
                      },
                      stateWidget: const CloudState(),
                    ),
                    addOnlyDivider(),
                    _settingItem(
                      title: 'hidden_artwork'.tr(),
                      icon: const Icon(AuIcon.hidden_artwork),
                      onTap: () async {
                        await Navigator.of(context)
                            .pushNamed(AppRouter.hiddenArtworksPage);
                      },
                    ),
                    addOnlyDivider(),
                    _settingItem(
                      title: 'autonomy_pro'.tr(),
                      icon: const Icon(AuIcon.add),
                      onTap: () async {
                        await Navigator.of(context)
                            .pushNamed(AppRouter.subscriptionPage);
                      },
                    ),
                    addOnlyDivider(),
                    _settingItem(
                      title: 'data_management'.tr(),
                      icon: const Icon(AuIcon.data_management),
                      onTap: () async {
                        await Navigator.of(context)
                            .pushNamed(AppRouter.dataManagementPage);
                      },
                    ),
                    addOnlyDivider(),
                    _settingItem(
                      title: 'help_us_improve'.tr(),
                      icon: const Icon(AuIcon.help_us),
                      onTap: () async {
                        await Navigator.of(context)
                            .pushNamed(AppRouter.helpUsPage);
                      },
                    ),
                    addOnlyDivider(),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
                  alignment: Alignment.bottomCenter,
                  child: _versionSection(),
                ),
              ],
            ),
            onNotification: (ScrollNotification notification) {
              var currentContext = _preferenceKey.currentContext;
              if (currentContext == null) {
                return false;
              }
              final renderObject = currentContext.findRenderObject();
              if (renderObject == null) {
                return false;
              }
              final viewport = RenderAbstractViewport.of(renderObject);
              final bottom = viewport.getOffsetToReveal(renderObject, 1).offset;
              final top = viewport.getOffsetToReveal(renderObject, 0).offset;
              final offset = notification.metrics.pixels;
              if (offset > 2 * (top + (bottom - top) / 3)) {
                _clearPendingSettings();
              }
              return false;
            },
          ),
        ),
      );

  void _clearPendingSettings() {
    if (!_pendingSettingsCleared) {
      unawaited(_configurationService.setPendingSettings(false));
      unawaited(_configurationService.setShouldShowSubscriptionHint(false));
      _pendingSettingsCleared = true;
    }
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> _checkVersion() async {
    final versionCheck = VersionCheck(showUpdateDialog: (versionCheck) {});
    await versionCheck.checkVersion(context);
    setState(() {
      _versionCheck = versionCheck;
    });
  }

  Widget _versionSection() {
    final theme = Theme.of(context);
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            child: Text(
              'eula'.tr(),
              style: theme.textTheme.ppMori400Grey12.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: AppColor.disabledColor,
              ),
            ),
            onTap: () async => Navigator.of(context)
                .pushNamed(AppRouter.githubDocPage, arguments: {
              'prefix': '/bitmark-inc/autonomy.io/main/apps/docs/',
              'document': 'eula.md',
              'title': 'eula'.tr(),
            }),
          ),
          Text(
            '_and'.tr(),
            style: theme.textTheme.ppMori400Grey12,
          ),
          GestureDetector(
            child: Text(
              'privacy_policy'.tr(),
              style: theme.textTheme.ppMori400Grey12.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: AppColor.disabledColor,
              ),
            ),
            onTap: () async => Navigator.of(context)
                .pushNamed(AppRouter.githubDocPage, arguments: {
              'prefix': '/bitmark-inc/autonomy.io/main/apps/docs/',
              'document': 'privacy.md',
              'title': 'privacy_policy'.tr(),
            }),
          ),
        ],
      ),
      const SizedBox(height: 24),
      if (_packageInfo != null)
        GestureDetector(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColor.auGrey),
              ),
              child: Text(
                'version_'.tr(
                  namedArgs: {
                    'version': _packageInfo!.version,
                    'buildNumber': _packageInfo!.buildNumber
                  },
                ),
                key: const Key('version'),
                style: theme.textTheme.ppMori400Grey14,
              ),
            ),
            onTap: () async {
              await injector<VersionService>().showReleaseNotes();
            }),
      const SizedBox(height: 10),
      StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
        final isLatestVersion = compareVersion(
                _versionCheck?.packageVersion ?? '',
                _versionCheck?.storeVersion ?? '') >=
            0;
        return GestureDetector(
          onTap: () async {
            if (isLatestVersion) {
              int now = DateTime.now().millisecondsSinceEpoch;
              if (now - _lastTap < 1000) {
                _consecutiveTaps++;
                if (_consecutiveTaps == 3) {
                  final newValue = await injector<ConfigurationService>()
                      .toggleDemoArtworksMode();
                  if (!mounted) {
                    return;
                  }
                  await UIHelper.showInfoDialog(
                      context,
                      'demo_mode'.tr(),
                      'demo_mode_en'.tr(args: [
                        if (newValue) 'enable'.tr() else 'disable'.tr()
                      ]),
                      autoDismissAfter: 1);
                }
              } else {
                _consecutiveTaps = 0;
              }
              _lastTap = now;
            } else {
              await UIHelper.showMessageAction(
                context,
                'update_available'.tr(),
                'want_to_update'.tr(
                  args: [
                    _versionCheck?.storeVersion ?? 'the_latest_version'.tr(),
                    _packageInfo?.version ?? ''
                  ],
                ),
                isDismissible: true,
                closeButton: 'close'.tr(),
                actionButton: 'update'.tr(),
                onAction: () {
                  injector<VersionService>().openLatestVersion();
                },
              );
            }
          },
          child: isLatestVersion
              ? Text(
                  'up_to_date'.tr(),
                  style: theme.textTheme.ppMori400Grey12,
                )
              : Text(
                  'update_to_the_latest_version'.tr(),
                  style: theme.textTheme.linkStyle14.copyWith(
                      fontWeight: FontWeight.w400,
                      fontFamily: AppTheme.ppMori,
                      decorationColor: AppColor.disabledColor,
                      color: AppColor.disabledColor,
                      shadows: [const Shadow()]),
                ),
        );
      }),
    ]);
  }
}
