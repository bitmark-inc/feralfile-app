//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_bloc.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_state.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PreferenceView extends StatelessWidget {
  const PreferenceView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.read<PreferencesBloc>().add(PreferenceInfoEvent());
    final theme = Theme.of(context);

    return BlocBuilder<PreferencesBloc, PreferenceState>(
        builder: (context, state) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "preferences".tr(),
            style: theme.textTheme.headline1,
          ),
          const SizedBox(height: 40),
          _preferenceItem(
            context,
            state.authMethodName,
            "use_device_passcode".tr(args: [
              state.authMethodName != "device_passcode".tr()
                  ? state.authMethodName
                  : "device_passcode".tr()
            ]),
            //"Use ${state.authMethodName != 'Device Passcode' ? state.authMethodName : 'device passcode'} to unlock the app, transact, and authenticate.",
            state.isDevicePasscodeEnabled,
            (value) {
              final newState = state.copyWith(isDevicePasscodeEnabled: value);
              context
                  .read<PreferencesBloc>()
                  .add(PreferenceUpdateEvent(newState));
            },
          ),
          addDivider(),
          _preferenceItem(
              context,
              "notifications".tr(),
              "receive_notification".tr(),
              //"Receive notifications when you get new NFTs, signing requests, or customer support messages.",
              state.isNotificationEnabled, (value) {
            final newState = state.copyWith(
                isNotificationEnabled: value, hasPendingSettings: false);
            final configService = injector<ConfigurationService>();
            configService.setPendingSettings(false);
            context
                .read<PreferencesBloc>()
                .add(PreferenceUpdateEvent(newState));
          }, pendingSetting: state.hasPendingSettings),
          addDivider(),
          _preferenceItemWithBuilder(
            context,
            "analytics".tr(),
            description: (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "contribute_anonymize".tr(),
                  //"Contribute anonymized, aggregate usage data to help improve Autonomy.",
                  style: theme.textTheme.bodyText1,
                ),
                const SizedBox(height: 10),
                GestureDetector(
                    child: Text(
                      "learn_anonymize".tr(),
                      textAlign: TextAlign.left,
                      style: ResponsiveLayout.isMobile
                          ? theme.textTheme.linkStyle
                          : theme.textTheme.linkStyle16,
                    ),
                    onTap: () => Navigator.of(context).pushNamed(
                          AppRouter.githubDocPage,
                          arguments: {
                            "document": "protect_your_usage_data.md",
                            "title": "how_protect_data".tr()
                            // "How we protect your usage data"
                          },
                        )),
              ],
            ),
            isEnabled: state.isAnalyticEnabled,
            onChanged: (value) {
              final newState = state.copyWith(isAnalyticEnabled: value);
              context
                  .read<PreferencesBloc>()
                  .add(PreferenceUpdateEvent(newState));
            },
          ),
          addDivider(),
          state.hasHiddenArtworks
              ? InkWell(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("hidden_artworks".tr(),
                          style: theme.textTheme.headline4),
                      Icon(
                        Icons.navigate_next,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context)
                        .pushNamed(AppRouter.hiddenArtworksPage);
                  },
                )
              : const SizedBox(),
        ],
      );
    });
  }

  Widget _preferenceItem(
    BuildContext context,
    String title,
    String description,
    bool isEnabled,
    ValueChanged<bool> onChanged, {
    bool pendingSetting = false,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(title, style: theme.textTheme.headline4),
                if (pendingSetting) ...[
                  const SizedBox(
                    width: 7,
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColor.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            CupertinoSwitch(
              value: isEnabled,
              onChanged: onChanged,
              activeColor: theme.colorScheme.primary,
            )
          ],
        ),
        const SizedBox(height: 7),
        Text(
          description,
          style: theme.textTheme.bodyText1,
        ),
      ],
    );
  }

  Widget _preferenceItemWithBuilder(BuildContext context, String title,
      {bool isEnabled = false,
      WidgetBuilder? description,
      ValueChanged<bool>? onChanged}) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: theme.textTheme.headline4),
            CupertinoSwitch(
              value: isEnabled,
              onChanged: onChanged,
              activeColor: theme.colorScheme.primary,
            )
          ],
        ),
        const SizedBox(height: 7),
        if (description != null) description(context),
      ],
    );
  }
}
