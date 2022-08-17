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
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
            margin: pageEdgeInsetsWithSubmitButton,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAvailable ? "backed_up".tr() : "sign_in_to_icloud".tr(),
                            style: theme.textTheme.headline1,
                          ),
                          addTitleSpace(),
                          Text(
                            "autonomy_will_auto_bk".tr(),
                            //"Autonomy will automatically back up all of your account information securely, including cryptographic material from accounts you manage as well as links to your accounts. If you ever lose your phone, you will be able to recover everything.",
                            style: theme.textTheme.bodyText1,
                          ),
                          if (isAvailable) ...[
                            const SizedBox(height: 40),
                            Center(
                                child: SvgPicture.asset(
                                    "assets/images/cloudOn.svg")),
                          ] else ...[
                            const SizedBox(height: 16),
                            Text(
                              "iCloud is currently turned off on your device. We recommend you enable it so we can safely back up your account.",
                              style: theme.textTheme.headline4,
                            ),
                            SizedBox(height: section == "settings" ? 40 : 80),
                            Center(
                                child: SvgPicture.asset(
                                    "assets/images/icloudKeychainGuide.svg")),
                            const SizedBox(height: 20),
                          ],
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
    final theme = Theme.of(context);
    switch (section) {
      case "nameAlias":
        if (isAvailable) {
          return Row(
            children: [
              Expanded(
                child: AuFilledButton(
                  text: "CONTINUE".toUpperCase(),
                  onPress: () => _continue(context),
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              TextButton(
                onPressed: () => openAppSettings(),
                child: Text(
                  "open_icloud_setting".tr(),
                  style: theme.textTheme.button,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: AuFilledButton(
                      text: "continue_without_icloud".tr().toUpperCase(),
                      onPress: () => _continue(context),
                    ),
                  ),
                ],
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
                child: AuFilledButton(
                  text: "open_icloud_setting".tr().toUpperCase(),
                  onPress: () => openAppSettings(),
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
          route.settings.name == AppRouter.settingsPage ||
          route.settings.name == AppRouter.wcConnectPage ||
          route.settings.name == AppRouter.homePage ||
          route.settings.name == AppRouter.homePageNoTransition);
    } else {
      doneOnboarding(context);
    }
  }
}
