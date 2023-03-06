//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/migration/key_sync_bloc.dart';
import 'package:autonomy_flutter/screen/migration/key_sync_state.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_radio_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class KeySyncPage extends StatefulWidget {
  const KeySyncPage({super.key});

  @override
  State<KeySyncPage> createState() => _KeySyncPageState();
}

class _KeySyncPageState extends State<KeySyncPage> {
  late String _selectedKeychain;
  @override
  void initState() {
    _selectedKeychain = KeyChain.device;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    context
        .read<KeySyncBloc>()
        .add(ToggleKeySyncEvent(_selectedKeychain == KeyChain.device));

    return BlocConsumer<KeySyncBloc, KeySyncState>(
      listener: (context, state) async {
        if (state.isProcessing == false) {
          Navigator.of(context).pop();
        }
        _selectedKeychain =
            state.isLocalSelected ? KeyChain.device : KeyChain.cloud;
      },
      builder: (context, state) {
        return Scaffold(
          appBar: getBackAppBar(
            context,
            title: "conflict_detected".tr(),
            onBack: () {
              if (state.isProcessing != true) {
                Navigator.of(context).pop();
              }
            },
          ),
          body: Container(
            margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        addTitleSpace(),
                        Text(
                          "conflict_keychains".tr(),
                          //"We have detected a conflict of keychains.",
                          style: theme.textTheme.ppMori700Black14,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "this_might_occur".tr(),
                          //"This might occur if you have signed in to a different cloud on this device. You are required to define a default keychain for identification before continuing with other actions inside the app:",
                          style: theme.textTheme.ppMori400Black14,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "select_your_default_keychain".tr(),
                          style: theme.textTheme.ppMori400Black14,
                        ),
                        const SizedBox(height: 12),
                        Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: theme.colorScheme.primary),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(5.0))),
                            child: GestureDetector(
                              onTap: () {
                                UIHelper.showDialog(
                                    context, "select_wallet_type".tr(),
                                    StatefulBuilder(builder: (
                                  BuildContext context,
                                  StateSetter keyChainState,
                                ) {
                                  return Column(
                                    children: [
                                      _keyChainOption(theme, KeyChain.device,
                                          keyChainState),
                                      addDivider(
                                          height: 40, color: AppColor.white),
                                      _keyChainOption(
                                          theme, KeyChain.cloud, keyChainState),
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
                                                if (state.isProcessing ==
                                                    true) {
                                                  return;
                                                }
                                                setState(() {});
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 32),
                                    paddingTitle: ResponsiveLayout
                                        .pageHorizontalEdgeInsets);
                              },
                              child: Container(
                                color: Colors.transparent,
                                child: Row(
                                  children: [
                                    Text(
                                      _selectedKeychain,
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
                        const SizedBox(height: 40.0),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: AppColor.auSuperTeal,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'how_it_work'.tr(),
                                style: ResponsiveLayout.isMobile
                                    ? theme.textTheme.ppMori700Black14
                                    : theme.textTheme.ppMori700Black16,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "data_contain".tr(),
                                //"All the data contained in the other keychain will be imported into the defined default one and converted into a full account. If you were using it as the main wallet, you will be able to continue to do so after the conversion. No keys are lost.",
                                style: ResponsiveLayout.isMobile
                                    ? theme.textTheme.ppMori400Black14
                                    : theme.textTheme.ppMori400Black16,
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => Navigator.of(context)
                                    .pushNamed(AppRouter.autonomySecurityPage),
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  "learn_security".tr(),
                                  style: (ResponsiveLayout.isMobile
                                          ? theme.textTheme.ppMori400Black14
                                          : theme.textTheme.ppMori400Black16)
                                      .copyWith(
                                          decoration: TextDecoration.underline),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        text: "proceed".tr(),
                        isProcessing: state.isProcessing == true,
                        onTap: state.isProcessing == true
                            ? null
                            : () {
                                context
                                    .read<KeySyncBloc>()
                                    .add(ProceedKeySyncEvent());
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _keyChainOption(
      ThemeData theme, String keyChain, StateSetter keyChainState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: () {
          keyChainState(() {
            _selectedKeychain = keyChain;
          });
        },
        child: Container(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Row(
            children: [
              Text(keyChain, style: theme.textTheme.ppMori400White14),
              const Spacer(),
              AuRadio(
                onTap: (value) {
                  keyChainState(() {
                    _selectedKeychain = keyChain;
                  });
                },
                value: keyChain,
                groupValue: _selectedKeychain,
                color: AppColor.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
