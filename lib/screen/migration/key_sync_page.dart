//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

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
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class KeySyncPage extends StatelessWidget {
  const KeySyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<KeySyncBloc, KeySyncState>(
      listener: (context, state) async {
        if (state.isProcessing == false) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final bloc = context.read<KeySyncBloc>();
        return Scaffold(
          appBar: getBackAppBar(
            context,
            title: 'conflict_detected'.tr(),
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
                          'conflict_keychains'.tr(),
                          //"We have detected a conflict of keychains.",
                          style: theme.textTheme.ppMori700Black14,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'this_might_occur'.tr(),
                          style: theme.textTheme.ppMori400Black14,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'select_your_default_keychain'.tr(),
                          style: theme.textTheme.ppMori400Black14,
                        ),
                        const SizedBox(height: 12),
                        Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: theme.colorScheme.primary),
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(5))),
                            child: GestureDetector(
                              onTap: () {
                                unawaited(UIHelper.showDialog(
                                    context,
                                    'select_wallet_type'.tr(),
                                    SelectKeychainView(
                                      onSelect: (bool isLocal) {
                                        bloc.add(ToggleKeySyncEvent());
                                      },
                                      onChange: (bool isLocal) {
                                        bloc.add(ChangeKeyChainEvent(isLocal));
                                      },
                                      defaultOption: state.isLocalSelected,
                                    ),
                                    isDismissible: true,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 32),
                                    paddingTitle: ResponsiveLayout
                                        .pageHorizontalEdgeInsets));
                              },
                              child: Container(
                                color: Colors.transparent,
                                child: Row(
                                  children: [
                                    Text(
                                      state.isLocalSelected
                                          ? KeyChain.device
                                          : KeyChain.cloud,
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
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: AppColor.feralFileHighlight,
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
                                'data_contain'.tr(),
                                style: ResponsiveLayout.isMobile
                                    ? theme.textTheme.ppMori400Black14
                                    : theme.textTheme.ppMori400Black16,
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => unawaited(Navigator.of(context)
                                    .pushNamed(AppRouter.autonomySecurityPage)),
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'learn_security'.tr(),
                                  style: (ResponsiveLayout.isMobile
                                          ? theme.textTheme.ppMori400Black14
                                          : theme.textTheme.ppMori400Black16)
                                      .copyWith(
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColor.primaryBlack,
                                  ),
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
                        text: 'proceed'.tr(),
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
}

class SelectKeychainView extends StatefulWidget {
  final Function(bool isLocal) onSelect;
  final Function(bool isLocal) onChange;
  final bool defaultOption;

  const SelectKeychainView(
      {required this.onSelect,
      required this.onChange,
      required this.defaultOption,
      super.key});

  @override
  State<SelectKeychainView> createState() => SelectKeychainViewState();
}

class SelectKeychainViewState extends State<SelectKeychainView> {
  late bool _selectedOption;

  @override
  void initState() {
    _selectedOption = widget.defaultOption;
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _option(
            context,
            true,
          ),
          addDivider(height: 40, color: AppColor.white),
          _option(
            context,
            false,
          ),
          const SizedBox(height: 40),
          Padding(
            padding: ResponsiveLayout.pageHorizontalEdgeInsets,
            child: Column(
              children: [
                PrimaryButton(
                  text: 'select'.tr(),
                  onTap: () {
                    widget.onSelect(_selectedOption);
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 10),
                OutlineButton(
                  onTap: () => Navigator.of(context).pop(),
                  text: 'cancel'.tr(),
                ),
              ],
            ),
          )
        ],
      );

  Widget _option(
    BuildContext context,
    bool option,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: () {
          widget.onChange(option);
          setState(() {
            _selectedOption = option;
          });
        },
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Row(
            children: [
              Text(option ? KeyChain.device : KeyChain.cloud,
                  style: theme.textTheme.ppMori400White14),
              const Spacer(),
              AuRadio(
                onTap: (value) {
                  widget.onChange(option);
                  setState(() {
                    _selectedOption = option;
                  });
                },
                value: option,
                groupValue: _selectedOption,
                color: AppColor.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
