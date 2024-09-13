import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

enum NotificationType {
  postcard;

  Map<String, dynamic> toJson() => {
        'name': name,
      };

  static NotificationType fromJson(Map<String, dynamic> map) {
    final value = NotificationType.values
        .firstWhere((element) => element.name == map['name']);
    return value;
  }
}

class NotificationPayload {
  int notificationId;
  NotificationType notificationType;
  String metadata;

  NotificationPayload(
      {required this.notificationId,
      required this.notificationType,
      required this.metadata});

  factory NotificationPayload.fromJson(Map<String, dynamic> map) =>
      NotificationPayload(
        notificationId: int.tryParse(map['notificationId'] ?? '') ?? 0,
        notificationType:
            NotificationType.fromJson(jsonDecode(map['notificationType'])),
        metadata: map['metadata'],
      );

  Map<String, String> toJson() => {
        'notificationId': notificationId.toString(),
        'notificationType': jsonEncode(notificationType.toJson()),
        'metadata': metadata,
      };
}

class NotificationService {
  final postcardChannelKey = 'autonomy.postcard.notification.key';
  final postcardChannelName = 'postcard_channel_name';
  final postcardChannelDescription = 'postcard_channel_description';
  ReceivedAction? _initialAction;

  ReceivedAction? get initialAction => _initialAction;

  NotificationService();

  Future<void> initNotification() async {
    try {
      await AwesomeNotifications().initialize(
          null, //'resource://drawable/res_app_icon',//
          [
            NotificationChannel(
              channelKey: postcardChannelKey,
              channelName: postcardChannelName,
              channelDescription: postcardChannelDescription,
              playSound: true,
              onlyAlertOnce: false,
              groupAlertBehavior: GroupAlertBehavior.Children,
              importance: NotificationImportance.High,
              defaultPrivacy: NotificationPrivacy.Private,
            )
          ],
          debug: true);

      _initialAction =
          await AwesomeNotifications().getInitialNotificationAction();
    } catch (e) {
      log.warning('NotificationService: initNotification: $e');
    }
  }

  Future<void> startListeningNotificationEvents() async {
    try {
      await AwesomeNotifications().setListeners(
        onActionReceivedMethod: onActionReceivedMethod,
        onNotificationCreatedMethod: onNotificationCreatedMethod,
        onNotificationDisplayedMethod: onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: onDismissActionReceivedMethod,
      );
    } catch (e) {
      log.warning('NotificationService: startListeningNotificationEvents: $e');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    final navigationService = injector<NavigationService>();
    if (receivedAction.actionType == ActionType.SilentAction ||
        receivedAction.actionType == ActionType.SilentBackgroundAction) {
      return;
    } else {
      try {
        final payload = receivedAction.payload;
        final notificationPayload = NotificationPayload.fromJson(payload ?? {});
        switch (notificationPayload.notificationType) {
          case NotificationType.postcard:
            final postcardIdentity = PostcardIdentity.fromJson(
                jsonDecode(notificationPayload.metadata));
            navigationService.popUntilHome();
            await navigationService.navigateTo(
                AppRouter.claimedPostcardDetailsPage,
                arguments: PostcardDetailPagePayload(ArtworkIdentity(
                    postcardIdentity.id, postcardIdentity.owner)));
        }
      } catch (e) {
        log.info('[NotificationService] onActionReceivedMethod error: $e]');
      }
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    log.info('[NotificationService] onNotificationCreatedMethod:'
        ' $receivedNotification');
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    log.info('[NotificationService] onNotificationDisplayedMethod:'
        ' $receivedNotification');
  }

  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
      ReceivedNotification receivedNotification) async {
    log.info('[NotificationService] onDismissActionReceivedMethod:'
        ' $receivedNotification');
  }

  Future<void> showNotification(
      {required String title,
      required String channelKey,
      int id = 0,
      String? body,
      Map<String, String>? payload}) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      return;
    }
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: channelKey,
            title: title,
            body: body,
            payload: payload));
  }
}
