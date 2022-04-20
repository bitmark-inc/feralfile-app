import 'package:autonomy_flutter/screen/settings/preferences/preferences_bloc.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_state.dart';
import 'package:autonomy_flutter/screen/settings/preferences/select_gallery_sorting_widget.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
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
            _gallerySortingByWidget(context, state.gallerySortBy),
            addDivider(),
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
            _preferenceItem(
              context,
              "Notifications",
              "Receive alerts about your transactions and other activities in your wallet.",
              state.isNotificationEnabled,
              (value) {
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

  Widget _gallerySortingByWidget(BuildContext context, String? gallerySortBy) {
    return TappableForwardRowWithContent(
      leftWidget: Text('Sort gallery by:', style: appTextTheme.headline4),
      bottomWidget: Text(
        gallerySortBy ?? 'Platform (default)',
        style: appTextTheme.bodyText1,
      ),
      onTap: () => showSelectGallerySortingDialog(context, gallerySortBy),
    );
  }

  void showSelectGallerySortingDialog(
      BuildContext context, String? gallerySortBy) {
    UIHelper.showDialog(
        context,
        'Gallery sorting',
        SelectGallerySortingWidget(
            sortBy: gallerySortBy ?? GallerySortProperty.Source),
        isDismissible: true);
  }
}
