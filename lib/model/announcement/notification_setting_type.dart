import 'package:easy_localization/easy_localization.dart';

enum NotificationSettingType {
  dailyArtworkReminders,
  exhibitionUpdates,
  collectionUpdates,
  eventsActivities,
  supportMessages;

  static NotificationSettingType? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'daily_artwork_reminders':
        return NotificationSettingType.dailyArtworkReminders;
      case 'exhibition_updates':
        return NotificationSettingType.exhibitionUpdates;
      case 'collection_updates':
        return NotificationSettingType.collectionUpdates;
      case 'events_activities':
        return NotificationSettingType.eventsActivities;
      case 'support_messages':
        return NotificationSettingType.supportMessages;
      default:
        return null;
    }
  }

  String toShortString() {
    switch (this) {
      case NotificationSettingType.dailyArtworkReminders:
        return 'daily_artwork_reminders';
      case NotificationSettingType.exhibitionUpdates:
        return 'exhibition_updates';
      case NotificationSettingType.collectionUpdates:
        return 'collection_updates';
      case NotificationSettingType.eventsActivities:
        return 'events_activities';
      case NotificationSettingType.supportMessages:
        return 'support_messages';
    }
  }

  String get title => toShortString().tr();

  String get description => '${toShortString()}_desc'.tr();
}
