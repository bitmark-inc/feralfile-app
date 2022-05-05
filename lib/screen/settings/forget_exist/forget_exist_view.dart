import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/forget_exist/forget_exist_bloc.dart';
import 'package:autonomy_flutter/screen/settings/forget_exist/forget_exist_state.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForgetExistView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);

    return BlocConsumer<ForgetExistBloc, ForgetExistState>(
        listener: (context, state) async {
      if (state.isProcessing == false) {
        Navigator.of(context).pushReplacementNamed(AppRouter.onboardingPage);
      }
    }, builder: (context, state) {
      return Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "• This action is irrevocable. It will completely delete all cryptographic keys and other data managed by Autonomy from your device and your device’s cloud backup. Autonomy will not be able to help you recover your deleted keys or data.\n• Linked accounts will be disconnected from Autonomy but not affected in any other way. You will continue to manage your keys in their respective wallets.\n• If you have an active subscription to Autonomy, you will need to manually cancel it in your device’s account settings.",
              style: theme.textTheme.bodyText1,
            ),
            SizedBox(
              height: 16,
            ),
            Row(
              children: [
                Checkbox(
                  checkColor: Colors.black,
                  activeColor: Colors.white,
                  side: BorderSide(color: Colors.white),
                  value: state.isChecked,
                  shape: CircleBorder(),
                  onChanged: (bool? value) {
                    print(value);
                    context
                        .read<ForgetExistBloc>()
                        .add(UpdateCheckEvent(value ?? false));
                  },
                ),
                SizedBox(
                  height: 16,
                ),
                Expanded(
                    child: Text(
                  "I understand that deleted accounts and keys are not recoverable and that I can’t undo this action.",
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
              text: "CONFIRM",
              onPress: () => context
                  .read<ForgetExistBloc>()
                  .add(ConfirmForgetExistEvent()),
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
