//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/screen/account/name_persona_page.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_state.dart';
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
import 'package:autonomy_flutter/view/crypto_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/services/tokens_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ImportAccountPage extends StatefulWidget {
  const ImportAccountPage({Key? key}) : super(key: key);

  @override
  State<ImportAccountPage> createState() => _ImportAccountPageState();
}

class _ImportAccountPageState extends State<ImportAccountPage>
    with AfterLayoutMixin<ImportAccountPage> {
  final TextEditingController _phraseTextController = TextEditingController();
  bool _isSubmissionEnabled = false;
  bool _isImporting = false;
  bool _isScanning = false;
  int scanCount = 0;
  Persona? _persona;

  bool isError = false;
  WalletType _walletType = WalletType.Autonomy;
  WalletType _walletTypeSelecting = WalletType.Autonomy;
  final metricClient = injector.get<MetricClientService>();

  @override
  void afterFirstLayout(BuildContext context) {
    metricClient.timerEvent(MixpanelEvent.backImportAccount);
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
                            text: "autonomy_will_import".tr(),
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
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                            border:
                                Border.all(color: theme.colorScheme.primary),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5.0))),
                        child: GestureDetector(
                          onTap: () {
                            UIHelper.showDialog(
                                context, "select_wallet_type".tr(),
                                StatefulBuilder(builder: (
                              BuildContext context,
                              StateSetter dialogState,
                            ) {
                              return Column(
                                children: [
                                  _walletTypeOption(
                                      theme, WalletType.Ethereum, dialogState),
                                  addDivider(height: 40, color: AppColor.white),
                                  _walletTypeOption(
                                      theme, WalletType.Tezos, dialogState),
                                  addDivider(height: 40, color: AppColor.white),
                                  _walletTypeOption(
                                      theme, WalletType.Autonomy, dialogState),
                                  const SizedBox(height: 40),
                                  Padding(
                                    padding: ResponsiveLayout
                                        .pageHorizontalEdgeInsets,
                                    child: Column(
                                      children: [
                                        PrimaryButton(
                                          text: "select".tr(),
                                          onTap: () {
                                            Navigator.of(context).pop();
                                            setState(() {
                                              _walletType =
                                                  _walletTypeSelecting;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        OutlineButton(
                                          onTap: () =>
                                              Navigator.of(context).pop(),
                                          text: "cancel".tr(),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              );
                            }),
                                isDismissible: true,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32),
                                paddingTitle:
                                    ResponsiveLayout.pageHorizontalEdgeInsets);
                          },
                          child: Container(
                            color: Colors.transparent,
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
                        hintMaxLines: 3,
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
            BlocConsumer<ScanWalletBloc, ScanWalletState>(
                listener: (scanContext, scanState) async {
              if (scanState.isScanning == false && _persona != null) {
                scanCount++;
                if (_walletType != WalletType.Autonomy || scanCount > 1) {
                  setState(() {
                    _isScanning = false;
                  });
                  if (scanState.addresses.isEmpty) {
                    Navigator.of(context).popAndPushNamed(
                        AppRouter.namePersonaPage,
                        arguments: NamePersonaPayload(uuid: _persona!.uuid));
                    return;
                  } else {
                    UIHelper.showScrollableDialog(
                      context,
                      BlocProvider.value(
                        value: context.read<ScanWalletBloc>(),
                        child: AddAddressToWallet(
                          addresses: scanState.addresses,
                          importedAddress: await _persona!.getAddresses(),
                          walletType: _walletTypeSelecting,
                          wallet: _persona!.wallet(),
                          onImport: (addresses) async {
                            final newPersona = await injector<AccountService>()
                                .addAddressPersona(_persona!, addresses);
                            if (!mounted) return;
                            Navigator.of(context).popAndPushNamed(
                                AppRouter.namePersonaPage,
                                arguments:
                                    NamePersonaPayload(uuid: newPersona.uuid));
                          },
                          onSkip: () {
                            UIHelper.hideInfoDialog(context);
                            Navigator.of(context).popAndPushNamed(
                                AppRouter.namePersonaPage,
                                arguments:
                                    NamePersonaPayload(uuid: _persona!.uuid));
                          },
                          scanNext: false,
                        ),
                      ),
                    );
                  }
                }
              }
            }, builder: (scanContext, scanState) {
              return PrimaryButton(
                enabled: _isSubmissionEnabled && !_isImporting && !_isScanning,
                isProcessing: _isImporting || _isScanning,
                text: _isImporting
                    ? "importing".tr()
                    : _isScanning
                        ? "scanning_addresses".tr()
                        : "import".tr(),
                onTap: () {
                  if (_isSubmissionEnabled) _import();
                },
              );
            }),
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
              Text(walletType.getString(),
                  style: theme.textTheme.ppMori400White14),
              const Spacer(),
              AuRadio<WalletType>(
                onTap: (value) {
                  setState(() {
                    _walletTypeSelecting = walletType;
                  });
                  dialogState(() {});
                },
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
        _isImporting = true;
      });
      final accountService = injector<AccountService>();

      final persona = await accountService.importPersona(
          _phraseTextController.text.trim(),
          walletType: _walletType);
      _persona = persona;
      log.info("Import wallet: ${_walletType.getString()}");
      // SideEffect: pre-fetch tokens
      final addresses = await persona.getAddresses();
      injector<TokensService>().fetchTokensForAddresses(addresses);
      setState(() {
        _isImporting = false;
        _isScanning = true;
      });

      if (!mounted) return;
      switch (_walletType) {
        case WalletType.Ethereum:
          context.read<ScanWalletBloc>().add(ScanEthereumWalletEvent(
              wallet: persona.wallet(),
              startIndex: 1,
              showEmptyAddresses: false,
              gapLimit: 2));
          break;
        case WalletType.Tezos:
          context.read<ScanWalletBloc>().add(ScanTezosWalletEvent(
              wallet: persona.wallet(),
              startIndex: 1,
              showEmptyAddresses: false,
              gapLimit: 2));
          break;
        default:
          context.read<ScanWalletBloc>().add(ScanEthereumWalletEvent(
              wallet: persona.wallet(),
              startIndex: 1,
              showEmptyAddresses: false,
              gapLimit: 2,
              isAdd: true));

          context.read<ScanWalletBloc>().add(ScanTezosWalletEvent(
              wallet: persona.wallet(),
              startIndex: 1,
              showEmptyAddresses: false,
              gapLimit: 2,
              isAdd: true));
      }
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
        _isImporting = false;
      });
    } catch (exception) {
      log.info("Import wallet fails ${exception.toString()}");
      if (!(exception is PlatformException &&
          exception.code == "importKey error")) {
        Sentry.captureException(exception);
      }
      UIHelper.hideInfoDialog(context);
      setState(() {
        isError = true;
        _isImporting = false;
      });
    }
  }
}
