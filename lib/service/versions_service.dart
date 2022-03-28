import 'dart:io';

import 'package:autonomy_flutter/gateway/pubdoc_api.dart';
import 'package:autonomy_flutter/model/version_info.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/helpers.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
    } else {
      // check to show Release Notes
      showReleaseNotes(onlyWhenUnread: true);
    }
  }

  Future showReleaseNotes({required bool onlyWhenUnread}) async {
    String currentVersion = (await PackageInfo.fromPlatform()).version;
    if (onlyWhenUnread) {
      final readVersion = _configurationService.getReadReleaseNotesVersion();
      if (compareVersion(readVersion, currentVersion) >= 0) {
        return;
      }
    }

    final releaseNotes = await getReleaseNotes(currentVersion);
    if (onlyWhenUnread && releaseNotes == "TBD") return;

    showReleaseNodeDialog(releaseNotes, currentVersion);
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
        return versionsInfo.devIOS;
      case 'prod_android':
        return versionsInfo.productionAndroid;
      default:
        return versionsInfo.devAndroid;
    }
  }

  Future<String> getReleaseNotes(String currentVersion) async {
    var releaseNotes = "";
    try {
      final version =
          currentVersion.substring(0, currentVersion.lastIndexOf("."));
      final app = (await isAppCenterBuild()) ? 'dev' : 'production';
      releaseNotes = await _pubdocAPI.getReleaseNotesContent(app, version);

      final textBegin = "## VERSION: $currentVersion\n";
      final iOSTextBegin = "#### [iOS]\n";
      final androidTextBegin = "#### [Android]\n";

      if (releaseNotes.contains(textBegin)) {
        releaseNotes = releaseNotes.split(textBegin)[1];
        releaseNotes = releaseNotes.split("\n## VERSION")[0];

        if (releaseNotes.contains(iOSTextBegin) ||
            releaseNotes.contains(androidTextBegin)) {
          if (Platform.isIOS) {
            releaseNotes = releaseNotes.split(iOSTextBegin)[1];
            releaseNotes = releaseNotes.split(androidTextBegin)[0];
          } else {
            releaseNotes = releaseNotes.split(androidTextBegin)[1];
          }
        }
      } else {
        releaseNotes = "TBD";
      }
    } catch (_) {
      releaseNotes = "TBD";
    }

    return releaseNotes;
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
                    launch(link, forceSafariVC: false);
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

  void showReleaseNodeDialog(String releaseNotes, String currentVersion) {
    final title = "What’s new?";
    if (UIHelper.currentDialogTitle == title) return;
    final context = _navigationService.navigatorKey.currentContext;
    if (context == null) return;
    final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);
    final heightFactor = releaseNotes.length <= 150 ? 0.52 : 0.8;

    releaseNotes = "[$currentVersion]\n\n" + releaseNotes;
    UIHelper.currentDialogTitle = title;

    _configurationService.setReadReleaseNotesInVersion(currentVersion);
    showModalBottomSheet<dynamic>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        builder: (context) {
          return FractionallySizedBox(
            heightFactor: heightFactor,
            child: Container(
              color: Color(0xFF737373),
              child: ClipPath(
                clipper: AutonomyTopRightRectangleClipper(),
                child: Container(
                  color: theme.backgroundColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.headline1),
                      SizedBox(height: 40),
                      Expanded(
                        child: Markdown(
                          data: releaseNotes.replaceAll('\n', '\u3164\n'),
                          softLineBreak: true,
                          padding: EdgeInsets.only(bottom: 50),
                          styleSheet: MarkdownStyleSheet.fromTheme(
                              AuThemeManager()
                                  .getThemeData(AppTheme.markdownTheme)),
                        ),
                      ),
                      SizedBox(height: 35),
                      Row(
                        children: [
                          Expanded(
                            child: AuFilledButton(
                              text: "CLOSE",
                              onPress: () => UIHelper.hideInfoDialog(context),
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
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }
}
