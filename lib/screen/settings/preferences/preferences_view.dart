//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_bloc.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_toggle.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PreferenceView extends StatelessWidget {
  const PreferenceView({super.key});

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
              'use_device_passcode'.tr(args: [
                if (state.authMethodName != 'device_passcode'.tr())
                  state.authMethodName
                else
                  'device_passcode'.tr()
              ]),
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
                'notifications'.tr(),
                'receive_notification'.tr(),
                state.isNotificationEnabled, (value) {
              final metricClient = injector<MetricClientService>();
              unawaited(metricClient.addEvent(MixpanelEvent.enableNotification,
                  data: {'isEnable': value}));
              metricClient.mixPanelClient.mixpanel
                  .getPeople()
                  .set(MixpanelProp.enableNotification, value);
              final newState = state.copyWith(
                  isNotificationEnabled: value, hasPendingSettings: false);
              final configService = injector<ConfigurationService>();
              if (value) {
                configService.showNotifTip.value = false;
              }
              unawaited(configService.setPendingSettings(false));
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
              'analytics'.tr(),
              description: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'contribute_anonymize'.tr(),
                    style: theme.textTheme.ppMori400Black14,
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                      child: Text(
                        'learn_anonymize'.tr(),
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
                      onTap: () => unawaited(Navigator.of(context).pushNamed(
                            AppRouter.githubDocPage,
                            arguments: {
                              'document': 'protect_your_usage_data.md',
                              'title': 'how_protect_data'.tr()
                              // "How we protect your usage data"
                            },
                          ))),
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
            AuToggle(
              value: isEnabled,
              onToggle: onChanged,
            ),
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
            AuToggle(value: isEnabled, onToggle: onChanged),
          ],
        ),
        const SizedBox(height: 7),
        if (description != null) description(context),
      ],
    );
  }
}
