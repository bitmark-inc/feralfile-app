//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/forget_exist/forget_exist_bloc.dart';
import 'package:autonomy_flutter/screen/settings/forget_exist/forget_exist_state.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundcheckbox/roundcheckbox.dart';

class ForgetExistView extends StatelessWidget {
  final String? event;

  const ForgetExistView({Key? key, this.event}) : super(key: key);

  String get descriptionEvent {
    return event == 'ConfirmEraseDeviceInfoEvent'
        ? "Your accounts and data from your device and your cloud backup will be deleted. Can restore with social recovery if you're done setup"
        : 'Your accounts and data from your device and your cloud backup will be deleted. Autonomy will not be able to help you recover access.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = AuThemeManager.get(AppTheme.sheetTheme);

    return BlocConsumer<ForgetExistBloc, ForgetExistState>(
        listener: (context, state) async {
      if (state.isProcessing == false) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRouter.onboardingPage, (_) => false);
      }
    }, builder: (context, state) {
      return Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "• ",
                  style: theme.textTheme.bodyText1,
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyText1,
                      children: <TextSpan>[
                        TextSpan(
                            text: "This action is irrevocable.",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(
                          text: " $descriptionEvent",
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
                  style: theme.textTheme.bodyText1,
                ),
                Expanded(
                  child: Text(
                    "This will not affect private keys of linked accounts",
                    style: theme.textTheme.bodyText1,
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "• ",
                  style: theme.textTheme.bodyText1,
                ),
                Expanded(
                  child: Text(
                    "If you have an active subscription, you will need to manually cancel it in your device’s settings.",
                    style: theme.textTheme.bodyText1,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 16,
            ),
            Row(
              children: [
                RoundCheckBox(
                  size: 24.0,
                  borderColor: Colors.white,
                  uncheckedColor: Colors.black,
                  checkedColor: Colors.white,
                  isChecked: state.isChecked,
                  checkedWidget: Icon(
                    CupertinoIcons.checkmark,
                    color: Colors.black,
                    size: 14,
                  ),
                  // checkedColor: Colors,
                  onTap: (bool? value) {
                    context
                        .read<ForgetExistBloc>()
                        .add(UpdateCheckEvent(value ?? false));
                  },
                ),
                SizedBox(width: 15),
                Expanded(
                    child: Text(
                  "I understand that this action cannot be undone.",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: "AtlasGrotesk",
                      fontWeight: FontWeight.w400,
                      height: 1.4),
                )),
              ],
            ),
            SizedBox(
              height: 40,
            ),
            AuFilledButton(
              text: state.isProcessing == true ? "FORGETTING…" : "CONFIRM",
              enabled: state.isProcessing == null && state.isChecked,
              onPress: state.isProcessing == null && state.isChecked
                  ? () {
                      if (event == 'ConfirmEraseDeviceInfoEvent') {
                        context
                            .read<ForgetExistBloc>()
                            .add(ConfirmEraseDeviceInfoEvent());
                      } else {
                        context
                            .read<ForgetExistBloc>()
                            .add(ConfirmForgetExistEvent());
                      }
                    }
                  : null,
              color: theme.primaryColor,
              isProcessing: state.isProcessing == true,
              textStyle: TextStyle(
                  color: theme.backgroundColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: "IBMPlexMono"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "CANCEL",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: "IBMPlexMono"),
              ),
            ),
          ],
        ),
      );
    });
  }
}
