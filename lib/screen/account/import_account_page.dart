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
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
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
                    SizedBox(
                      height: 160,
                      child: Column(
                        children: [
                          AuTextField(
                            title: "",
                            placeholder: "enter_recovery_phrase".tr(),
                            //"Enter recovery phrase with each word separated by a space",
                            keyboardType: TextInputType.multiline,
                            expanded: true,
                            maxLines: null,
                            hintMaxLines: 2,
                            controller: _phraseTextController,
                            isError: isError,
                            onChanged: (value) {
                              final numberOfWords =
                                  value.trim().split(' ').length;
                              setState(() {
                                _isSubmissionEnabled =
                                    numberOfWords == 12 || numberOfWords == 24;
                                isError = false;
                              });
                            },
                          ),
                        ],
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

  Future _import() async {
    try {
      setState(() {
        isError = false;
      });

      final persona = await injector<AccountService>()
          .importPersona(_phraseTextController.text.trim());
      // SideEffect: pre-fetch tokens
      injector<TokensService>().fetchTokensForAddresses([
        (await persona.wallet().getETHEip55Address()),
        (await persona.wallet().getTezosAddress()),
      ]);

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
