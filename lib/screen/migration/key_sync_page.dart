//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/migration/key_sync_bloc.dart';
import 'package:autonomy_flutter/screen/migration/key_sync_state.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

class KeySyncPage extends StatelessWidget {
  const KeySyncPage({Key? key}) : super(key: key);

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
                          "conflict_detected".tr(),
                          style: theme.textTheme.headline1,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          "conflict_keychains".tr(),
                          //"We have detected a conflict of keychains.",
                          style: theme.textTheme.headline4,
                        ),
                        Text(
                          "this_might_occur".tr(),
                          //"This might occur if you have signed in to a different cloud on this device. You are required to define a default keychain for identification before continuing with other actions inside the app:",
                          style: theme.textTheme.bodyText1,
                        ),
                        const SizedBox(height: 20),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            "device_keychain".tr(),
                            style: theme.textTheme.headline4,
                          ),
                          trailing: Transform.scale(
                            scale: 1.25,
                            child: Radio(
                              activeColor: theme.colorScheme.primary,
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
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'cloud_keychain'.tr(),
                            style: theme.textTheme.headline4,
                          ),
                          trailing: Transform.scale(
                            scale: 1.25,
                            child: Radio(
                              activeColor: theme.colorScheme.primary,
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
                        const SizedBox(height: 40.0),
                        Container(
                          padding: const EdgeInsets.all(10),
                          color: AppColor.secondaryDimGreyBackground,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'how_it_work'.tr(),
                                style: ResponsiveLayout.isMobile
                                    ? theme.textTheme.atlasDimgreyBold14
                                    : theme.textTheme.atlasDimgreyBold16,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "data_contain".tr(),
                                //"All the data contained in the other keychain will be imported into the defined default one and converted into a full account. If you were using it as the main wallet, you will be able to continue to do so after the conversion. No keys are lost.",
                                style: ResponsiveLayout.isMobile
                                    ? theme.textTheme.atlasBlackNormal14
                                    : theme.textTheme.atlasBlackNormal16,
                              ),
                              const SizedBox(height: 10),
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
                                  style: ResponsiveLayout.isMobile
                                      ? theme.textTheme.linkStyle
                                      : theme.textTheme.linkStyle16,
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
