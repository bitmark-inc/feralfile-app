import 'dart:io';

import 'package:autonomy_flutter/gateway/pubdoc_api.dart';
import 'package:autonomy_flutter/model/version_info.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/helpers.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionService {
  final PubdocAPI _pubdocAPI;
  final ConfigurationService _configurationService;
  final NavigationService _navigationService;

  VersionService(
      this._pubdocAPI, this._configurationService, this._navigationService);

  void checkForUpdate() async {
    if (UIHelper.currentDialogTitle == "Update Required") return;

    final versionInfo = await getVersionInfo();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;

    if (compareVersion(versionInfo.requiredVersion, currentVersion) > 0) {
      showForceUpdateDialog(versionInfo.link);
    }
  }

  Future<VersionInfo> getVersionInfo() async {
    final versionsInfo = await _pubdocAPI.getVersionsInfo();
    final isAppCenter = await isAppCenterBuild();
    var app = '';
    app += (isAppCenter) ? "dev" : "prod";
    app += Platform.isIOS ? "_ios" : "_android";

    switch (app) {
      case 'prod_ios':
        return versionsInfo.productionIOS;
      case 'dev_ios':
        return versionsInfo.testIOS;
      case 'prod_android':
        return versionsInfo.productionAndroid;
      default:
        return versionsInfo.testAndroid;
    }
  }

  void showForceUpdateDialog(String link) {
    final context = _navigationService.navigatorKey.currentContext;
    if (context == null) return;

    final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);
    UIHelper.showDialog(
        context,
        "Update Required",
        Column(children: [
          Text(
              "There is a newer version available for download! Please update the app to continue.",
              style: theme.textTheme.bodyText1),
          SizedBox(height: 35),
          Row(
            children: [
              Expanded(
                child: AuFilledButton(
                  text: "UPDATE",
                  onPress: () {
                    launch(link);
                  },
                  color: theme.primaryColor,
                  textStyle: TextStyle(
                      color: theme.backgroundColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: "IBMPlexMono"),
                ),
              ),
            ],
          ),
        ]));
  }
}
