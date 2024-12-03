//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/forget_exist/forget_exist_bloc.dart';
import 'package:autonomy_flutter/screen/settings/forget_exist/forget_exist_state.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundcheckbox/roundcheckbox.dart';

class ForgetExistView extends StatelessWidget {
  const ForgetExistView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<ForgetExistBloc, ForgetExistState>(
        listener: (context, state) async {
          if (state.isProcessing == false) {
            await Navigator.of(context).pushNamedAndRemoveUntil(
                AppRouter.onboardingPage, (_) => false);
          }
        },
        builder: (context, state) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: theme.primaryTextTheme.ppMori400White14,
                    ),
                    Expanded(
                      child: RichText(
                        textScaler: MediaQuery.textScalerOf(context),
                        text: TextSpan(
                          style: theme.primaryTextTheme.ppMori400White14,
                          children: <TextSpan>[
                            TextSpan(
                                text: 'action_irrevocable'.tr(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            TextSpan(
                              text: ' ${'accounts_delete'.tr()}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: theme.primaryTextTheme.ppMori400White14,
                    ),
                    Expanded(
                      child: Text(
                        'this_not_effect'.tr(),
                        style: theme.primaryTextTheme.ppMori400White14,
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: theme.primaryTextTheme.ppMori400White14,
                    ),
                    Expanded(
                      child: Text(
                        'active_subscription'.tr(),
                        style: theme.primaryTextTheme.ppMori400White14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => context
                      .read<ForgetExistBloc>()
                      .add(UpdateCheckEvent(!state.isChecked)),
                  child: Row(
                    children: [
                      RoundCheckBox(
                        size: 24,
                        borderColor: theme.colorScheme.secondary,
                        uncheckedColor: theme.colorScheme.primary,
                        checkedColor: theme.colorScheme.secondary,
                        isChecked: state.isChecked,
                        checkedWidget: Icon(
                          CupertinoIcons.checkmark,
                          color: theme.colorScheme.primary,
                          size: 14,
                        ),
                        onTap: (bool? value) {
                          context
                              .read<ForgetExistBloc>()
                              .add(UpdateCheckEvent(value ?? false));
                        },
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                          child: Text(
                        'i_understand'.tr(),
                        //"I understand that this action cannot be undone.",
                        style: theme.primaryTextTheme.ppMori400White12,
                      )),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                PrimaryButton(
                  text: state.isProcessing == true
                      ? 'forgetting'.tr()
                      : 'h_confirm'.tr(),
                  color: state.isProcessing == null && state.isChecked
                      ? null
                      : theme.disableColor,
                  onTap: state.isProcessing == null && state.isChecked
                      ? () {
                          context
                              .read<ForgetExistBloc>()
                              .add(ConfirmForgetExistEvent());
                        }
                      : null,
                  isProcessing: state.isProcessing == true,
                ),
                const SizedBox(
                  height: 10,
                ),
                OutlineButton(
                  onTap: () => Navigator.pop(context),
                  text: 'cancel_dialog'.tr(),
                ),
              ],
            ));
  }
}
