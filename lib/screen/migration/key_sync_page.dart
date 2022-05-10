import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/migration/key_sync_bloc.dart';
import 'package:autonomy_flutter/screen/migration/key_sync_state.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class KeySyncPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<KeySyncBloc, KeySyncState>(
      listener: (context, state) async {
        if (state.isProcessing == false) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: getBackAppBar(
            context,
            onBack: () {
              if (state.isProcessing != true) {
                Navigator.of(context).pop();
              }
            },
          ),
          body: Container(
            margin: pageEdgeInsets,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Conflict detected",
                          style: appTextTheme.headline1,
                        ),
                        SizedBox(height: 40),
                        Text(
                          "We have detected a conflict of keychains.",
                          style: appTextTheme.headline4,
                        ),
                        Text(
                          "This might occur if you have signed in to a different cloud on this device. You are required to define a default keychain for identification before continuing with other actions inside the app:",
                          style: appTextTheme.bodyText1,
                        ),
                        SizedBox(height: 20),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            "Cloud keychain",
                            style: appTextTheme.headline4,
                          ),
                          trailing: Transform.scale(
                            scale: 1.25,
                            child: Radio(
                              activeColor: Colors.black,
                              value: true,
                              groupValue: state.isLocalSelected,
                              onChanged: (bool? value) {
                                if (state.isProcessing == true) {
                                  return;
                                }
                                context
                                    .read<KeySyncBloc>()
                                    .add(ToggleKeySyncEvent(value ?? true));
                              },
                            ),
                          ),
                        ),
                        Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Device keychain',
                            style: appTextTheme.headline4,
                          ),
                          trailing: Transform.scale(
                            scale: 1.25,
                            child: Radio(
                              activeColor: Colors.black,
                              value: false,
                              groupValue: state.isLocalSelected,
                              onChanged: (bool? value) {
                                if (state.isProcessing == true) {
                                  return;
                                }
                                context
                                    .read<KeySyncBloc>()
                                    .add(ToggleKeySyncEvent(value ?? true));
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 40.0),
                        Container(
                          padding: EdgeInsets.all(10),
                          color: AppColorTheme.secondaryDimGreyBackground,
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('How does it work?',
                                    style: TextStyle(
                                        color: AppColorTheme.secondaryDimGrey,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "AtlasGrotesk",
                                        height: 1.377)),
                                SizedBox(height: 5),
                                Text(
                                    "All the data contained in the other keychain will be imported into the defined default one and converted into a full account. If you were using it as the main wallet, you will be able to continue to do so after the conversion. No keys are lost.",
                                    style: bodySmall),
                                SizedBox(height: 10),
                                TextButton(
                                    onPressed: () => Navigator.of(context)
                                        .pushNamed(
                                            AppRouter.autonomySecurityPage),
                                    child: Text(
                                        'Learn about Autonomy security...',
                                        style: linkStyle),
                                    style: TextButton.styleFrom(
                                      minimumSize: Size.zero,
                                      padding: EdgeInsets.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    )),
                              ]),
                        )
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: AuFilledButton(
                        text: "PROCEED",
                        isProcessing: state.isProcessing == true,
                        onPress: state.isProcessing == true
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
