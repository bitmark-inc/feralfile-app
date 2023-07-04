//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/cloud_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/external_app_info_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CloudPage extends StatelessWidget {
  final String section;

  const CloudPage({Key? key, required this.section}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: canPop == true
            ? () {
                Navigator.of(context).pop();
              }
            : null,
        title: "back_up".tr(),
      ),
      body: _contentWidget(context),
    );
  }

  Widget _contentWidget(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<bool>(
        valueListenable: injector<CloudService>().isAvailableNotifier,
        builder: (BuildContext context, bool isAvailable, Widget? child) {
          return Container(
            margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          addTitleSpace(),
                          Text(
                            "autonomy_will_auto_bk".tr(),
                            //"Autonomy will automatically back up all of your account information securely, including cryptographic material from accounts you manage as well as links to your accounts. If you ever lose your phone, you will be able to recover everything.",
                            style: theme.textTheme.ppMori400Black14,
                          ),
                          const SizedBox(height: 15),
                          ExternalAppInfoView(
                            icon: Image.asset("assets/images/iCloudDrive.png"),
                            appName: "icloud_drive".tr(),
                            status: isAvailable
                                ? "turned_on".tr()
                                : "turned_off".tr(),
                            statusColor: isAvailable
                                ? AppColor.auQuickSilver
                                : AppColor.red,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            isAvailable
                                ? "you_backed_up".tr()
                                : "recommend_icloud_key".tr(),
                            style: theme.textTheme.ppMori700Black14,
                          ),
                        ]),
                  ),
                ),
                _buttonsGroup(context, isAvailable),
              ],
            ),
          );
        });
  }

  Widget _buttonsGroup(BuildContext context, bool isAvailable) {
    switch (section) {
      case "nameAlias":
        if (isAvailable) {
          return Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: "continue".tr(),
                  onTap: () => _continue(context),
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              PrimaryButton(
                onTap: () => openAppSettings(),
                text: "open_icloud_setting".tr(),
              ),
              const SizedBox(height: 10),
              OutlineButton(
                text: "skip".tr(),
                onTap: () => _continue(context),
                color: AppColor.white,
                borderColor: AppColor.primaryBlack,
                textColor: AppColor.primaryBlack,
              ),
            ],
          );
        }

      case "settings":
        if (isAvailable) {
          return const SizedBox();
        } else {
          return Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  onTap: () => openAppSettings(),
                  text: "open_icloud_setting".tr(),
                ),
              ),
            ],
          );
        }

      default:
        return const SizedBox();
    }
  }

  void _continue(BuildContext context) {
    if (injector<ConfigurationService>().isDoneOnboarding()) {
      Navigator.of(context).popUntil((route) =>
          route.settings.name == AppRouter.claimSelectAccountPage ||
          route.settings.name == AppRouter.wcConnectPage ||
          route.settings.name == AppRouter.homePage ||
          route.settings.name == AppRouter.homePageNoTransition);
    } else {
      doneOnboarding(context);
    }
  }
}
