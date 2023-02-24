//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/view/au_radio_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nft_collection/services/tokens_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ImportAccountPage extends StatefulWidget {
  const ImportAccountPage({Key? key}) : super(key: key);

  @override
  State<ImportAccountPage> createState() => _ImportAccountPageState();
}

class _ImportAccountPageState extends State<ImportAccountPage> {
  final TextEditingController _phraseTextController = TextEditingController();
  bool _isSubmissionEnabled = false;

  bool isError = false;
  WalletType _walletType = WalletType.Autonomy;
  WalletType _walletTypeSelecting = WalletType.Autonomy;
  final metricClient = injector.get<MetricClientService>();

  @override
  void initState() {
    metricClient.timerEvent(MixpanelEvent.backImportAccount);
    super.initState();
  }

  @override
  void dispose() {
    _phraseTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customLinkStyle = theme.textTheme.ppMori400Black14
        .copyWith(decoration: TextDecoration.underline);
    return Scaffold(
      appBar: getBackAppBar(context, onBack: () {
        metricClient.addEvent(MixpanelEvent.backImportAccount);
        Navigator.of(context).pop();
      }, title: "import_wallet".tr()),
      body: Container(
        margin: ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    addTitleSpace(),
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.ppMori400Black14,
                        children: <TextSpan>[
                          TextSpan(
                            text: "ia_importing_your_account_".tr(),
                          ),
                          Platform.isIOS
                              ? TextSpan(
                                  text: 'icloud_keychain'.tr(),
                                  style: customLinkStyle,
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.of(context)
                                            .pushNamed(AppRouter.githubDocPage,
                                                arguments: {
                                              "prefix":
                                                  "/bitmark-inc/autonomy.io/main/apps/docs/",
                                              "document": "security-ios.md",
                                              "title": ""
                                            }),
                                )
                              : TextSpan(
                                  text: 'android_block_store'.tr(),
                                  style: customLinkStyle,
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.of(context)
                                            .pushNamed(AppRouter.githubDocPage,
                                                arguments: {
                                              "prefix":
                                                  "/bitmark-inc/autonomy.io/main/apps/docs/",
                                              "document": "security-android.md",
                                              "title": ""
                                            }),
                                ),
                          const TextSpan(
                            text: ".",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    learnMoreAboutAutonomySecurityWidget(
                      context,
                      title: 'learn_why_this_is_safe...'.tr(),
                    ),
                    const SizedBox(height: 15),
                    Text("1. ${"select_wallet_type".tr()}.",
                        style: theme.textTheme.ppMori400Black14),
                    const SizedBox(height: 15),
                    Container(
                        decoration: BoxDecoration(
                            border:
                                Border.all(color: theme.colorScheme.primary),
                            borderRadius: BorderRadiusGeometry.lerp(
                                const BorderRadius.all(Radius.circular(5)),
                                const BorderRadius.all(Radius.circular(5)),
                                5)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: GestureDetector(
                            onTap: () {
                              UIHelper.showDialog(context, "select_your_wallet",
                                  StatefulBuilder(builder: (
                                BuildContext context,
                                StateSetter dialogState,
                              ) {
                                return Column(
                                  children: [
                                    _walletTypeOption(theme,
                                        WalletType.Autonomy, dialogState),
                                    addDivider(
                                        height: 40, color: AppColor.white),
                                    _walletTypeOption(theme,
                                        WalletType.Ethereum, dialogState),
                                    addDivider(
                                        height: 40, color: AppColor.white),
                                    _walletTypeOption(
                                        theme, WalletType.Tezos, dialogState),
                                    const SizedBox(height: 40),
                                    PrimaryButton(
                                      text: "select".tr(),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        setState(() {
                                          _walletType = _walletTypeSelecting;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    OutlineButton(
                                      onTap: () => Navigator.of(context).pop(),
                                      text: "cancel".tr(),
                                    )
                                  ],
                                );
                              }),
                                  isDismissible: true,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 32));
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                  color: Colors.transparent),
                              child: Row(
                                children: [
                                  Text(
                                    _walletType.getString(),
                                    style: theme.textTheme.ppMori400Black14,
                                  ),
                                  const Spacer(),
                                  RotatedBox(
                                    quarterTurns: 1,
                                    child: Icon(
                                      AuIcon.chevron_Sm,
                                      size: 12,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        )),
                    const SizedBox(height: 15),
                    Text("2. ${"enter_your_seed".tr()}.",
                        style: theme.textTheme.ppMori400Black14),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 160,
                      child: AuTextField(
                        labelSemantics: "enter_seed",
                        title: "",
                        placeholder: "enter_recovery_phrase".tr(),
                        //"Enter recovery phrase with each word separated by a space",
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        hintMaxLines: 2,
                        controller: _phraseTextController,
                        isError: isError,
                        onChanged: (value) {
                          final numberOfWords = value.trim().split(' ').length;
                          setState(() {
                            _isSubmissionEnabled =
                                numberOfWords == 12 || numberOfWords == 24;
                            isError = false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Visibility(
                      visible: isError,
                      child: Text(
                        'invalid_recovery_phrase'.tr(),
                        style: theme.textTheme.ppMori400Black12.copyWith(
                          color: AppColor.red,
                        ),
                      ),
                    ),
                    const SizedBox(),
                  ],
                ),
              ),
            ),
            PrimaryButton(
              enabled: _isSubmissionEnabled,
              text: "h_confirm".tr(),
              onTap: () {
                if (_isSubmissionEnabled) _import();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _walletTypeOption(
      ThemeData theme, WalletType walletType, StateSetter dialogState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _walletTypeSelecting = walletType;
          });
          dialogState(() {});
        },
        child: Container(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Row(
            children: [
              Text(
                walletType.getString(),
                style: theme.textTheme.ppMori400White14,
              ),
              const Spacer(),
              AuRadio<WalletType>(
                onTap: (value) {},
                value: _walletTypeSelecting,
                groupValue: walletType,
                color: AppColor.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _import() async {
    try {
      setState(() {
        isError = false;
      });

      final persona = await injector<AccountService>().importPersona(
          _phraseTextController.text.trim(),
          walletType: _walletType);
      log.info("Import wallet: ${_walletType.getString()}");
      // SideEffect: pre-fetch tokens
      final addresses = await persona.getAddresses();
      injector<TokensService>().fetchTokensForAddresses(addresses);

      if (!mounted) return;

      Navigator.of(context)
          .popAndPushNamed(AppRouter.namePersonaPage, arguments: persona.uuid);
    } on AccountImportedException catch (e) {
      showErrorDiablog(
          context,
          ErrorEvent(
              null,
              "already_imported".tr(),
              "ai_you’ve_already".tr(),
              //"You’ve already imported this account to Autonomy.",
              ErrorItemState.seeAccount), defaultAction: () {
        Navigator.of(context).pushNamed(
          AppRouter.personaDetailsPage,
          arguments: e.persona,
        );
      });
      setState(() {
        isError = true;
      });
    } catch (exception) {
      if (!(exception is PlatformException &&
          exception.code == "importKey error")) {
        Sentry.captureException(exception);
      }
      UIHelper.hideInfoDialog(context);
      setState(() {
        isError = true;
      });
    }
  }
}
