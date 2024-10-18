//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/external_app_info_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:open_settings/open_settings.dart';

class CloudAndroidPage extends StatefulWidget {
  final CloudAndroidPagePayload payload;

  const CloudAndroidPage({required this.payload, super.key});

  @override
  State<CloudAndroidPage> createState() => _CloudAndroidPageState();
}

class _CloudAndroidPageState extends State<CloudAndroidPage>
    with WidgetsBindingObserver {
  bool? isEncryptionAvailable;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    setState(() {
      isEncryptionAvailable = widget.payload.isEncryptionAvailable;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      unawaited(checkCloudBackup());
    }
  }

  Future checkCloudBackup() async {
    if (isEncryptionAvailable == true) {
      return;
    }

    final accountService = injector<AccountService>();
    final isAndroidEndToEndEncryptionAvailable =
        await accountService.isAndroidEndToEndEncryptionAvailable();

    if (isEncryptionAvailable == isAndroidEndToEndEncryptionAvailable) {
      return;
    }

    if (isEncryptionAvailable == null &&
        isAndroidEndToEndEncryptionAvailable != null) {
      await accountService.androidBackupKeys();
    }

    setState(() {
      isEncryptionAvailable = isAndroidEndToEndEncryptionAvailable;
    });
  }

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
                      'autonomy_will_auto_bk_android'.tr(),
                      style: theme.textTheme.ppMori400Black14,
                    ),
                    const SizedBox(height: 15),
                    ExternalAppInfoView(
                      icon: Image.asset('assets/images/googleCloud.png'),
                      appName: 'google_cloud'.tr(),
                      status: isEncryptionAvailable == true
                          ? 'turned_on'.tr()
                          : 'turned_off'.tr(),
                      statusColor: isEncryptionAvailable != true
                          ? AppColor.red
                          : AppColor.auQuickSilver,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      isEncryptionAvailable == true
                          ? 'you_backed_up'.tr()
                          : isEncryptionAvailable == false
                              ? 'automatic_google_cloud_bks'.tr()
                              : 'recommend_google_cloud'.tr(),
                      style: theme.textTheme.ppMori700Black14,
                    ),
                  ]),
            ),
          ),
          _buttonsGroup(context),
        ],
      ),
    );
  }

  Widget _buttonsGroup(BuildContext context) {
    if (isEncryptionAvailable == true) {
      return const SizedBox();
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: 'open_device_setting'.tr(),
                  onTap: () => isEncryptionAvailable == false
                      ? unawaited(OpenSettings.openMainSetting())
                      : unawaited(OpenSettings.openAddAccountSetting()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlineButton(
            onTap: () => _continue(context),
            text: 'skip'.tr(),
            color: AppColor.white,
            borderColor: AppColor.primaryBlack,
            textColor: AppColor.primaryBlack,
          ),
        ],
      );
    }
  }

  void _continue(BuildContext context) {
    Navigator.of(context).pop();
  }
}

// payload class
class CloudAndroidPagePayload {
  final bool? isEncryptionAvailable;

  CloudAndroidPagePayload({this.isEncryptionAvailable});
}
