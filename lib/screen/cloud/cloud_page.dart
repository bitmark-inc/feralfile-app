//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

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
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CloudPage extends StatelessWidget {
  final CloudPagePayload payload;

  const CloudPage({required this.payload, super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: canPop
            ? () {
                Navigator.of(context).pop();
              }
            : null,
        title: 'back_up'.tr(),
      ),
      body: _contentWidget(context),
    );
  }

  Widget _contentWidget(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<bool>(
        valueListenable: injector<CloudService>().isAvailableNotifier,
        builder: (BuildContext context, bool isAvailable, Widget? child) =>
            Container(
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
                              'autonomy_will_auto_bk'.tr(),
                              style: theme.textTheme.ppMori400Black14,
                            ),
                            const SizedBox(height: 15),
                            ExternalAppInfoView(
                              icon:
                                  Image.asset('assets/images/iCloudDrive.png'),
                              appName: 'icloud_drive'.tr(),
                              status: isAvailable
                                  ? 'turned_on'.tr()
                                  : 'turned_off'.tr(),
                              statusColor: isAvailable
                                  ? AppColor.auQuickSilver
                                  : AppColor.red,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              isAvailable
                                  ? 'you_backed_up'.tr()
                                  : 'recommend_icloud_key'.tr(),
                              style: theme.textTheme.ppMori700Black14,
                            ),
                          ]),
                    ),
                  ),
                  _buttonsGroup(context, isAvailable),
                ],
              ),
            ));
  }

  Widget _buttonsGroup(BuildContext context, bool isAvailable) {
    switch (payload.section) {
      case 'nameAlias':
        if (isAvailable) {
          return Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: 'continue'.tr(),
                  onTap: () => _continue(context),
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              PrimaryButton(
                onTap: () => unawaited(openAppSettings()),
                text: 'open_icloud_setting'.tr(),
              ),
              const SizedBox(height: 10),
              OutlineButton(
                text: 'skip'.tr(),
                onTap: () => _continue(context),
                color: AppColor.white,
                borderColor: AppColor.primaryBlack,
                textColor: AppColor.primaryBlack,
              ),
            ],
          );
        }

      case 'settings':
        if (isAvailable) {
          return const SizedBox();
        } else {
          return Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  onTap: () => unawaited(openAppSettings()),
                  text: 'open_icloud_setting'.tr(),
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
          route.settings.name == AppRouter.tbConnectPage ||
          route.settings.name == AppRouter.wc2ConnectPage ||
          route.settings.name == AppRouter.homePage ||
          route.settings.name == AppRouter.homePageNoTransition);
    } else {
      unawaited(doneOnboarding(context));
    }
  }
}

// payload class
class CloudPagePayload {
  final String section;

  CloudPagePayload({required this.section});
}
