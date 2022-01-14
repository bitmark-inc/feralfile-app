import 'package:autonomy_flutter/screen/settings/preferences/preferences_bloc.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PreferenceView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    context.read<PreferencesBloc>().add(PreferenceInfoEvent());

    return BlocBuilder<PreferencesBloc, PreferenceState>(
        builder: (context, state) {
      return Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Preferences",
              style: Theme.of(context).textTheme.headline1,
            ),
            _preferenceItem(
              context,
              "Device passcode",
              "Use device passcode to unlock the app, transact, and authenticate.",
              state.isDevicePasscodeEnabled,
              (value) {
                final newState = PreferenceState(value,
                    state.isNotificationEnabled, state.isAnalyticEnabled);
                context
                    .read<PreferencesBloc>()
                    .add(PreferenceUpdateEvent(newState));
              },
            ),
            Divider(),
            _preferenceItem(
              context,
              "Notifications",
              "Receive alerts about your transactions and other activities in your wallet.",
              state.isNotificationEnabled,
              (value) {
                final newState = PreferenceState(state.isDevicePasscodeEnabled,
                    value, state.isAnalyticEnabled);
                context
                    .read<PreferencesBloc>()
                    .add(PreferenceUpdateEvent(newState));
              },
            ),
            Divider(),
            _preferenceItem(
              context,
              "Analytics",
              "Contribute anonymized, aggregate usage data to help improve Autonomy.",
              state.isAnalyticEnabled,
              (value) {
                final newState = PreferenceState(state.isDevicePasscodeEnabled,
                    state.isNotificationEnabled, value);
                context
                    .read<PreferencesBloc>()
                    .add(PreferenceUpdateEvent(newState));
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _preferenceItem(BuildContext context, String title, String description,
      bool isEnabled, ValueChanged<bool> onChanged) {
    return Container(
      padding: EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.headline5),
              Switch(value: isEnabled, onChanged: onChanged)
            ],
          ),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ],
      ),
    );
  }
}
