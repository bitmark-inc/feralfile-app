//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/announcement/notification_setting_type.dart';

abstract class NotificationSettingsEvent {}

class GetNotificationSettingsEvent extends NotificationSettingsEvent {}

class UpdateNotificationSettingsEvent extends NotificationSettingsEvent {
  final Map<NotificationSettingType, bool> updateSettings;

  UpdateNotificationSettingsEvent(this.updateSettings);
}

class NotificationSettingsState {
  final Map<NotificationSettingType, bool> notificationSettings;

  NotificationSettingsState(this.notificationSettings);

  NotificationSettingsState copyWith({
    Map<NotificationSettingType, bool>? notificationSettings,
  }) =>
      NotificationSettingsState(
        notificationSettings ?? this.notificationSettings,
      );
}
