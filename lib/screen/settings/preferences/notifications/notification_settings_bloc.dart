import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/model/announcement/notification_setting_type.dart';
import 'package:autonomy_flutter/screen/settings/preferences/notifications/notification_settings_state.dart';

class NotificationSettingsBloc
    extends AuBloc<NotificationSettingsEvent, NotificationSettingsState> {
  final IAPApi _iapApi;

  NotificationSettingsBloc(this._iapApi)
      : super(NotificationSettingsState({})) {
    on<GetNotificationSettingsEvent>((event, emit) async {
      final resp = await _iapApi.getNotificationSettings();
      final Map<NotificationSettingType, bool> newState = {};
      resp.forEach((key, value) {
        final type = NotificationSettingType.fromString(key);
        if (type != null && value is bool) {
          newState[type] = value;
        }
      });
      emit(NotificationSettingsState(newState));
    });
    on<UpdateNotificationSettingsEvent>((event, emit) async {
      final body = event.updateSettings
          .map((key, value) => MapEntry(key.toShortString(), value));
      await _iapApi.updateNotificationSettings(body);
      final Map<NotificationSettingType, bool> newValues =
          state.notificationSettings;
      event.updateSettings.forEach((key, value) {
        newValues[key] = value;
      });
      emit(NotificationSettingsState(newValues));
    });
  }
}
