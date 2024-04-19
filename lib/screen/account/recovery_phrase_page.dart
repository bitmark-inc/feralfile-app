//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/cloud_service.dart';
import 'package:autonomy_flutter/service/local_auth_service.dart';
import 'package:autonomy_flutter/util/secure_screen_channel.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:open_settings/open_settings.dart';
import 'package:permission_handler/permission_handler.dart';

class RecoveryPhrasePayload {
  final List<String> words;
  final String passphrase;

  RecoveryPhrasePayload({required this.words, required this.passphrase});
}

class RecoveryPhrasePage extends StatefulWidget {
  final RecoveryPhrasePayload payload;

  const RecoveryPhrasePage({required this.payload, super.key});

  @override
  State<RecoveryPhrasePage> createState() => _RecoveryPhrasePageState();
}

class _RecoveryPhrasePageState extends State<RecoveryPhrasePage> {
  bool _isShow = false;
  bool? _isBackUpAvailable;

  @override
  void initState() {
    super.initState();
    SecureScreenChannel.setSecureFlag(true);
    WidgetsBinding.instance.addPostFrameCallback((context) {
      unawaited(_checkBackUpAvailable());
    });
  }

  @override
  void dispose() {
    SecureScreenChannel.setSecureFlag(false);
    super.dispose();
  }

  Future<void> _checkBackUpAvailable() async {
    if (Platform.isIOS) {
      final isAvailable = injector<CloudService>().isAvailableNotifier.value;
      _isBackUpAvailable = isAvailable;
    } else {
      final isAndroidEndToEndEncryptionAvailable =
          await injector<AccountService>()
              .isAndroidEndToEndEncryptionAvailable();
      _isBackUpAvailable = isAndroidEndToEndEncryptionAvailable ?? false;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final roundNumber =
        widget.payload.words.length ~/ 2 + widget.payload.words.length % 2;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: 'your_recovery_phrase'.tr(),
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    addTitleSpace(),
                    _getBackUpState(context),
                    Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Table(
                              children: List.generate(
                                roundNumber,
                                (index) =>
                                    _tableRow(context, index, roundNumber),
                              ),
                              border: TableBorder.all(
                                  color: AppColor.auLightGrey,
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            if (widget.payload.passphrase.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: AppColor.auLightGrey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: 'passphrase'.tr(),
                                        style: theme
                                            .textTheme.ppMori400FFQuickSilver14,
                                      ),
                                      const TextSpan(text: '  '),
                                      TextSpan(
                                          text: widget.payload.passphrase,
                                          style:
                                              theme.textTheme.ppMori400Black14),
                                    ],
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                        if (!_isShow)
                          Positioned.fill(
                            child: ClipRect(
                                child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Center(
                                  child: ConstrainedBox(
                                constraints: const BoxConstraints.tightFor(
                                    width: 168, height: 45),
                                child: PrimaryButton(
                                  text: 'tap_to_reveal'.tr(),
                                  onTap: () async {
                                    final didAuthenticate =
                                        await LocalAuthenticationService
                                            .checkLocalAuth();

                                    if (!didAuthenticate) {
                                      return;
                                    }
                                    setState(() {
                                      _isShow = !_isShow;
                                    });
                                    Future.delayed(
                                      const Duration(seconds: 60),
                                      () {
                                        if (mounted) {
                                          setState(() {
                                            _isShow = !_isShow;
                                          });
                                        }
                                      },
                                    );
                                  },
                                ),
                              )),
                            )),
                          ),
                      ],
                    ),
                    _recommend(context),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            _settingButton(context)
          ],
        ),
      ),
    );
  }

  Widget _rowItem(BuildContext context, int index) {
    final theme = Theme.of(context);
    final isNull = index >= widget.payload.words.length;
    final word = isNull ? '' : widget.payload.words[index];
    NumberFormat formatter = NumberFormat('00');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            alignment: Alignment.centerRight,
            child: Text(isNull ? '' : formatter.format(index + 1),
                style: theme.textTheme.ppMori400Grey14),
          ),
          const SizedBox(width: 16),
          Text(word, style: theme.textTheme.ppMori400Black14),
        ],
      ),
    );
  }

  Widget _getBackUpState(BuildContext context) {
    final theme = Theme.of(context);
    final customLinkStyle = theme.textTheme.ppMori400Black14.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: AppColor.primaryBlack,
    );
    if (_isBackUpAvailable == null) {
      return const SizedBox();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SRP_is_crucial'.tr(),
          style: theme.textTheme.ppMori400Black14,
        ),
        const SizedBox(height: 12),
        Text(
          'as_a_non_custodial_wallet'.tr(),
          style: theme.textTheme.ppMori400Black14,
        ),
        const SizedBox(height: 12),
        Text('remember_if_you_lose_your_SRP'.tr(),
            style: theme.textTheme.ppMori700Black14),
        const SizedBox(height: 12),
        if (_isBackUpAvailable == true) ...[
          RichText(
            text: TextSpan(
              style: theme.textTheme.ppMori400Black14,
              children: <TextSpan>[
                TextSpan(
                  text: 'yrp_we’ve_safely'.tr(),
                ),
                if (Platform.isIOS)
                  TextSpan(
                    text: 'icloud_keychain'.tr(),
                    style: customLinkStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => unawaited(Navigator.of(context)
                              .pushNamed(AppRouter.githubDocPage, arguments: {
                            'prefix':
                                '/bitmark-inc/autonomy.io/main/apps/docs/',
                            'document': 'security-ios.md',
                            'title': ''
                          })),
                  )
                else
                  TextSpan(
                    text: 'android_block_store'.tr(),
                    style: customLinkStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => unawaited(Navigator.of(context)
                              .pushNamed(AppRouter.githubDocPage, arguments: {
                            'prefix':
                                '/bitmark-inc/autonomy.io/main/apps/docs/',
                            'document': 'security-android.md',
                            'title': ''
                          })),
                  ),
                TextSpan(
                  text: 'yrp_you_may_also'.tr(),
                ),
              ],
            ),
          ),
        ] else ...[
          RichText(
            text: TextSpan(
              style: theme.textTheme.ppMori400Black14,
              children: <TextSpan>[
                if (Platform.isIOS)
                  TextSpan(
                    text: 'icloud_keychain'.tr(),
                    style: customLinkStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => unawaited(Navigator.of(context)
                              .pushNamed(AppRouter.githubDocPage, arguments: {
                            'prefix':
                                '/bitmark-inc/autonomy.io/main/apps/docs/',
                            'document': 'security-ios.md',
                            'title': ''
                          })),
                  )
                else
                  TextSpan(
                    text: 'android_block_store'.tr(),
                    style: customLinkStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => unawaited(Navigator.of(context)
                              .pushNamed(AppRouter.githubDocPage, arguments: {
                            'prefix':
                                '/bitmark-inc/autonomy.io/main/apps/docs/',
                            'document': 'security-android.md',
                            'title': ''
                          })),
                  ),
                TextSpan(
                  text: '_is_'.tr(),
                ),
                TextSpan(
                  text: 'turned_off'.tr().toLowerCase(),
                  style: theme.textTheme.ppMori700Black14,
                ),
                TextSpan(
                  text: 'unable_backup'.tr(),
                  style: theme.textTheme.ppMori400Black14,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _recommend(BuildContext context) {
    final theme = Theme.of(context);
    if (_isBackUpAvailable != false) {
      return const SizedBox();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Text(
            Platform.isAndroid
                ? 'recommend_google_cloud'.tr()
                : 'recommend_icloud_key'.tr(),
            style: theme.textTheme.ppMori700Black14),
      ],
    );
  }

  Widget _settingButton(BuildContext context) {
    if (_isBackUpAvailable != false) {
      return const SizedBox();
    }
    return Row(
      children: [
        Expanded(
          child: Platform.isAndroid
              ? OutlineButton(
                  text: 'open_device_setting'.tr(),
                  onTap: () => unawaited(OpenSettings.openAddAccountSetting()),
                  color: AppColor.white,
                  borderColor: AppColor.primaryBlack,
                  textColor: AppColor.primaryBlack,
                )
              : OutlineButton(
                  onTap: () => unawaited(openAppSettings()),
                  text: 'open_icloud_setting'.tr(),
                  color: AppColor.white,
                  borderColor: AppColor.primaryBlack,
                  textColor: AppColor.primaryBlack,
                ),
        ),
      ],
    );
  }

  TableRow _tableRow(BuildContext context, int index, int itemsEachCol) =>
      TableRow(children: [
        _rowItem(context, index),
        _rowItem(context, index + itemsEachCol),
      ]);
}
