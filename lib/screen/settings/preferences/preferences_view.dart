//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_bloc.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_state.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PreferenceView extends StatelessWidget {
  const PreferenceView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.read<PreferencesBloc>().add(PreferenceInfoEvent());

    return BlocBuilder<PreferencesBloc, PreferenceState>(
        builder: (context, state) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Preferences",
            style: appTextTheme.headline1,
          ),
          const SizedBox(height: 24),
          _preferenceItem(
            context,
            'Immediate info view',
            "Enable info view when tapping on a thumbnail.",
            state.isImmediateInfoViewEnabled,
            (value) {
              final newState =
                  state.copyWith(isImmediateInfoViewEnabled: value);
              context
                  .read<PreferencesBloc>()
                  .add(PreferenceUpdateEvent(newState));
            },
          ),
          const Divider(),
          _preferenceItem(
            context,
            state.authMethodName,
            "Use ${state.authMethodName != 'Device Passcode' ? state.authMethodName : 'device passcode'} to unlock the app, transact, and authenticate.",
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
            "Notifications",
            "Receive notifications when you get new NFTs, signing requests, or customer support messages.",
            state.isNotificationEnabled,
            (value) {
              final newState = state.copyWith(isNotificationEnabled: value);
              context
                  .read<PreferencesBloc>()
                  .add(PreferenceUpdateEvent(newState));
            },
          ),
          addDivider(),
          _preferenceItemWithBuilder(
            context,
            "Analytics",
            description: (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Contribute anonymized, aggregate usage data to help improve Autonomy.",
                  style: appTextTheme.bodyText1,
                ),
                const SizedBox(height: 10),
                GestureDetector(
                    child: const Text("Learn how we anonymize your data...",
                        textAlign: TextAlign.left, style: linkStyle),
                    onTap: () => Navigator.of(context).pushNamed(
                          AppRouter.githubDocPage,
                          arguments: {
                            "document": "protect_your_usage_data.md",
                            "title": "How we protect your usage data"
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
                      Text("Hidden artworks", style: appTextTheme.headline4),
                      const Icon(Icons.navigate_next, color: Colors.black),
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

  Widget _preferenceItem(BuildContext context, String title, String description,
      bool isEnabled, ValueChanged<bool> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: appTextTheme.headline4),
            CupertinoSwitch(
              value: isEnabled,
              onChanged: onChanged,
              activeColor: Colors.black,
            )
          ],
        ),
        const SizedBox(height: 7),
        Text(
          description,
          style: appTextTheme.bodyText1,
        ),
      ],
    );
  }

  Widget _preferenceItemWithBuilder(BuildContext context, String title,
      {bool isEnabled = false,
      WidgetBuilder? description,
      ValueChanged<bool>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: appTextTheme.headline4),
            CupertinoSwitch(
              value: isEnabled,
              onChanged: onChanged,
              activeColor: Colors.black,
            )
          ],
        ),
        const SizedBox(height: 7),
        if (description != null) description(context),
      ],
    );
  }
}
