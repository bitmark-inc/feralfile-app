//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/forget_exist/forget_exist_bloc.dart';
import 'package:autonomy_flutter/screen/settings/forget_exist/forget_exist_state.dart';

import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundcheckbox/roundcheckbox.dart';

class ForgetExistView extends StatelessWidget {
  const ForgetExistView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<ForgetExistBloc, ForgetExistState>(
        listener: (context, state) async {
      if (state.isProcessing == false) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRouter.onboardingPage, (_) => false);
      }
    }, builder: (context, state) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "• ",
                style: theme.primaryTextTheme.bodyText1,
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: theme.primaryTextTheme.bodyText1,
                    children: <TextSpan>[
                      TextSpan(
                          text: "action_irrevocable".tr(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                        text: "accounts_delete".tr(),
                        //" Your accounts and data from your device and your cloud backup will be deleted. Autonomy will not be able to help you recover access.",
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
                "• ",
                style: theme.primaryTextTheme.bodyText1,
              ),
              Expanded(
                child: Text(
                  "this_not_effect".tr(),
                  //"This will not affect private keys of linked accounts",
                  style: theme.primaryTextTheme.bodyText1,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "• ",
                style: theme.primaryTextTheme.bodyText1,
              ),
              Expanded(
                child: Text(
                  "active_subscription".tr(),
                  //"If you have an active subscription, you will need to manually cancel it in your device’s settings.",
                  style: theme.primaryTextTheme.bodyText1,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          GestureDetector(
            onTap: () => context
                .read<ForgetExistBloc>()
                .add(UpdateCheckEvent(!state.isChecked)),
            child: Row(
              children: [
                RoundCheckBox(
                  size: 24.0,
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
                  "i_understand".tr(),
                  //"I understand that this action cannot be undone.",
                  style: theme.primaryTextTheme.headline5,
                )),
              ],
            ),
          ),
          const SizedBox(
            height: 40,
          ),
          AuFilledButton(
            text:
                state.isProcessing == true ? "forgetting".tr() : "confirm".tr(),
            enabled: state.isProcessing == null && state.isChecked,
            onPress: () {
              context.read<ForgetExistBloc>().add(ConfirmForgetExistEvent());
            },
            color: theme.colorScheme.secondary,
            isProcessing: state.isProcessing == true,
            textStyle: theme.textTheme.button,
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "cancel".tr(),
              style: theme.primaryTextTheme.button,
            ),
          ),
        ],
      );
    });
  }
}
