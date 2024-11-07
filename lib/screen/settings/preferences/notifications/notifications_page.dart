import 'package:autonomy_flutter/model/announcement/notification_setting_type.dart';
import 'package:autonomy_flutter/screen/settings/preferences/notifications/notification_settings_bloc.dart';
import 'package:autonomy_flutter/screen/settings/preferences/notifications/notification_settings_state.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/preference_item.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/extensions/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationSettingsBloc _bloc;

  static const _horizontalPadding = EdgeInsets.symmetric(horizontal: 15);

  @override
  void initState() {
    super.initState();
    _bloc = context.read<NotificationSettingsBloc>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(context, onBack: () {
        Navigator.of(context).pop();
      }),
      body: BlocBuilder<NotificationSettingsBloc, NotificationSettingsState>(
        bloc: _bloc,
        builder: (context, state) {
          final settings = state.notificationSettings.entries.toList()
            ..sort((a, b) => a.key.index.compareTo(b.key.index));
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: _horizontalPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Text('manage_system_permissions'.tr(),
                          style: theme.textTheme.ppMori700Black16),
                      const SizedBox(height: 15),
                      Text('manage_system_permissions_desc'.tr(),
                          style: theme.textTheme.ppMori400Black14),
                      const SizedBox(height: 15),
                      PrimaryButton(
                        text: 'go_to_os_settings'.tr(),
                        onTap: () async {
                          await AwesomeNotifications()
                              .showNotificationConfigPage();
                        },
                      ),
                      const SizedBox(height: 40),
                      Text('notification_types'.tr(),
                          style: theme.textTheme.ppMori700Black16),
                      const SizedBox(height: 5),
                      Text('notification_types_desc'.tr(),
                          style: theme.textTheme.ppMori400Black14),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...settings
                    .map((e) => _notificationItem(context, e.key, e.value)),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _notificationItem(
          BuildContext context, NotificationSettingType type, bool isEnabled) =>
      Column(
        children: [
          Padding(
            padding: _horizontalPadding,
            child: PreferenceItem(
                title: type.title,
                description: type.description,
                isEnabled: isEnabled,
                onChanged: (value) {
                  final updateSettings = {type: value};
                  _bloc.add(UpdateNotificationSettingsEvent(updateSettings));
                }),
          ),
          addDivider(),
        ],
      );
}
