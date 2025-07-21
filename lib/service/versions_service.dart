//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/gateway/pubdoc_api.dart';
import 'package:autonomy_flutter/model/version_info.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/helpers.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class VersionService {
  Future<void> checkForUpdate();

  Future<void> showReleaseNotes({String? currentVersion});

  Future<void> openLatestVersion();
}

class VersionServiceImpl implements VersionService {
  final PubdocAPI _pubdocAPI;
  final ConfigurationService _configurationService;
  final NavigationService _navigationService;

  VersionServiceImpl(
      this._pubdocAPI, this._configurationService, this._navigationService);

  Future checkForUpdate() async {
    if (kDebugMode) {
      return;
    }
    if (UIHelper.currentDialogTitle == 'update_required'.tr()) {
      return;
    }

    final versionInfo = await getVersionInfo();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;

    if (compareVersion(versionInfo.requiredVersion, currentVersion) > 0) {
      await showForceUpdateDialog(versionInfo.link);
    } else {
      // check to show Release Notes
      await showReleaseNotes(currentVersion: currentVersion);
    }
  }

  Future showReleaseNotes({String? currentVersion}) async {
    if (currentVersion != null) {
      final readVersion = _configurationService.getReadReleaseNotesVersion();
      if (readVersion == null ||
          compareVersion(readVersion, currentVersion) >= 0) {
        unawaited(
            _configurationService.setReadReleaseNotesInVersion(currentVersion));
        return;
      }
    }

    final releaseNotes = await getReleaseNotes(currentVersion);
    if (releaseNotes == 'TBD') {
      return;
    }

    if (currentVersion != null) {
      await _configurationService.setReadReleaseNotesInVersion(currentVersion);
    }
    await showReleaseNodeDialog(releaseNotes);
  }

  Future<VersionInfo> getVersionInfo() async {
    final versionsInfo = await _pubdocAPI.getVersionsInfo();
    final isAppCenter = await isAppCenterBuild();
    var app = '';
    app += isAppCenter ? 'dev' : 'prod';
    app += Platform.isIOS ? '_ios' : '_android';

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

  Future<String> getReleaseNotes(String? currentVersion) async {
    var releaseNotes = '';
    try {
      final app = (await isAppCenterBuild()) ? 'dev' : 'production';
      releaseNotes = await _pubdocAPI.getReleaseNotesContent(app);

      if (currentVersion != null) {
        final textBegin = '[#] $currentVersion';
        if (!releaseNotes.startsWith(textBegin)) {
          releaseNotes = 'TBD';
        }
      }
    } catch (_) {
      releaseNotes = 'TBD';
    }

    return releaseNotes;
  }

  Future showForceUpdateDialog(String link) async {
    final context = _navigationService.navigatorKey.currentContext;
    if (context == null) {
      return;
    }

    final theme = Theme.of(context);
    await UIHelper.showDialog(
      context,
      'update_required'.tr(),
      PopScope(
        canPop: false,
        child: Column(children: [
          Text('newer_version'.tr(), style: theme.textTheme.ppMori400White14),
          const SizedBox(height: 35),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: 'update'.tr(),
                  onTap: () {
                    final uri = Uri.tryParse(link);
                    if (uri != null) {
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Future showReleaseNodeDialog(String releaseNotes) async {
    var screenKey =
        'what_new'.tr(); // avoid showing multiple what's new screens
    if (UIHelper.currentDialogTitle == screenKey) {
      return;
    }

    UIHelper.currentDialogTitle = screenKey;

    await _navigationService.navigateTo(AppRouter.releaseNotesPage,
        arguments: releaseNotes);
  }

  Future openLatestVersion() async {
    final versionInfo = await getVersionInfo();
    final uri = Uri.tryParse(versionInfo.link);
    if (uri != null) {
      unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
    }
  }
}
