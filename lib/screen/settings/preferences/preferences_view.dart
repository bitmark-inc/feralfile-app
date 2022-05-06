import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/github_doc.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_bloc.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_state.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:flutter/cupertino.dart';
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
              style: appTextTheme.headline1,
            ),
            SizedBox(height: 24),
            _preferenceItem(
              context,
              'Immediate playback',
              "Enable playback when tapping on a thumbnail.",
              state.isImmediatePlaybackEnabled,
              (value) {
                final newState =
                    state.copyWith(isImmediatePlaybackEnabled: value);
                context
                    .read<PreferencesBloc>()
                    .add(PreferenceUpdateEvent(newState));
              },
            ),
            addDivider(),
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
            _preferenceItemWithBuilder(
              context,
              "Notifications",
              description: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Contribute anonymized, aggregate usage data to help improve Autonomy.",
                    style: appTextTheme.bodyText1,
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                      child: Text("Learn how we anonymize your data...",
                          textAlign: TextAlign.left,
                          style: appTextTheme.bodyText1
                              ?.copyWith(decoration: TextDecoration.underline)),
                      onTap: () => Navigator.of(context).pushNamed(
                            GithubDocPage.tag,
                            arguments: {
                              "document": "protect_your_usage_data.md",
                              "title": "How we protect your usage data"
                            },
                          )),
                ],
              ),
              isEnabled: state.isNotificationEnabled,
              onChanged: (value) {
                final newState = state.copyWith(isNotificationEnabled: value);
                context
                    .read<PreferencesBloc>()
                    .add(PreferenceUpdateEvent(newState));
              },
            ),
            addDivider(),
            _preferenceItem(
              context,
              "Analytics",
              "Contribute anonymized, aggregate usage data to help improve Autonomy.",
              state.isAnalyticEnabled,
              (value) {
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
                        Icon(Icons.navigate_next, color: Colors.black),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed(AppRouter.hiddenArtworksPage);
                    },
                  )
                : SizedBox(),
          ],
        ),
      );
    });
  }

  Widget _preferenceItem(BuildContext context, String title, String description,
      bool isEnabled, ValueChanged<bool> onChanged) {
    return Container(
      child: Column(
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
          SizedBox(height: 7),
          Text(
            description,
            style: appTextTheme.bodyText1,
          ),
        ],
      ),
    );
  }

  Widget _preferenceItemWithBuilder(BuildContext context, String title,
      {bool isEnabled = false,
      WidgetBuilder? description,
      ValueChanged<bool>? onChanged}) {
    return Container(
      child: Column(
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
          SizedBox(height: 7),
          if (description != null) description(context),
        ],
      ),
    );
  }
}
