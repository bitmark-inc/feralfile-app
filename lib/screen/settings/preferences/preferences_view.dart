//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_bloc.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_switch/flutter_switch.dart';

class PreferenceView extends StatelessWidget {
  const PreferenceView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    context.read<PreferencesBloc>().add(PreferenceInfoEvent());
    final theme = Theme.of(context);
    return BlocBuilder<PreferencesBloc, PreferenceState>(
        builder: (context, state) {
      final padding =
          ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: padding,
            child: _preferenceItem(
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
          ),
          addDivider(),
          Padding(
            padding: padding,
            child: _preferenceItem(
                context,
                "notifications".tr(),
                "receive_notification".tr(),
                //"Receive notifications when you get new NFTs, signing requests, or customer support messages.",
                state.isNotificationEnabled, (value) {
              final metricClient = injector<MetricClientService>();
              metricClient.addEvent(MixpanelEvent.enableNotification,
                  data: {'isEnable': value});
              final newState = state.copyWith(
                  isNotificationEnabled: value, hasPendingSettings: false);
              final configService = injector<ConfigurationService>();
              configService.setPendingSettings(false);
              context
                  .read<PreferencesBloc>()
                  .add(PreferenceUpdateEvent(newState));
            }, pendingSetting: state.hasPendingSettings),
          ),
          addDivider(),
          Padding(
            padding: padding,
            child: _preferenceItemWithBuilder(
              context,
              "analytics".tr(),
              description: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "contribute_anonymize".tr(),
                    //"Contribute anonymized, aggregate usage data to help improve Autonomy.",
                    style: theme.textTheme.ppMori400Black14,
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                      child: Text(
                        "learn_anonymize".tr(),
                        textAlign: TextAlign.left,
                        style: ResponsiveLayout.isMobile
                            ? theme.textTheme.ppMori400Black14.copyWith(
                                decoration: TextDecoration.underline,
                                decorationStyle: TextDecorationStyle.solid,
                                decorationColor: Colors.black,
                                decorationThickness: 1.1,
                              )
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
          ),
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
                Text(title, style: theme.textTheme.ppMori400Black16),
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
            FlutterSwitch(
              height: 25,
              width: 48,
              toggleSize: 19.2,
              padding: 2,
              value: isEnabled,
              onToggle: onChanged,
              activeColor: AppColor.auSuperTeal,
              inactiveColor: Colors.transparent,
              toggleColor: AppColor.primaryBlack,
              inactiveSwitchBorder: Border.all(),
            )
          ],
        ),
        const SizedBox(height: 7),
        Text(
          description,
          style: theme.textTheme.ppMori400Black14,
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
            Text(title, style: theme.textTheme.ppMori400Black16),
            FlutterSwitch(
              height: 25,
              width: 48,
              toggleSize: 19.2,
              padding: 2,
              value: isEnabled,
              onToggle: onChanged ?? (bool p) {},
              activeColor: AppColor.auSuperTeal,
              inactiveColor: Colors.transparent,
              toggleColor: AppColor.primaryBlack,
              inactiveSwitchBorder: Border.all(),
            )
          ],
        ),
        const SizedBox(height: 7),
        if (description != null) description(context),
      ],
    );
  }
}
