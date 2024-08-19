import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/model/additional_data/additional_data.dart';
import 'package:autonomy_flutter/model/announcement/announcement.dart';
import 'package:autonomy_flutter/model/announcement/announcement_local.dart';
import 'package:autonomy_flutter/model/announcement/announcement_request.dart';
import 'package:autonomy_flutter/service/announcement/announcement_store.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';

abstract class AnnouncementService {
  Future<List<Announcement>> fetchAnnouncements();

  List<AnnouncementLocal> getLocalAnnouncements();

  Future<void> markAsRead(String? announcementContentId);

  List<AnnouncementLocal> getUnreadAnnouncements();

  AnnouncementLocal? getAnnouncement(String? announcementContentId);

  AnnouncementLocal? getOldestAnnouncement();

  Future<void> showOldestAnnouncement({bool shouldRepeat = true});
}

class AnnouncementServiceImpl implements AnnouncementService {
  final IAPApi _iapApi;
  final AnnouncementStore _announcementStore;
  final ConfigurationService _configurationService;

  AnnouncementServiceImpl(
    this._iapApi,
    this._announcementStore,
    this._configurationService,
  );

  static const int _fetchSize = 10;

  @override
  Future<List<Announcement>> fetchAnnouncements() async {
    final lastPullTime = _configurationService.getLastPullAnnouncementTime();
    final request = AnnouncementRequest(
      lastPullTime: lastPullTime,
      size: _fetchSize,
    );
    log.info('Fetching announcements with request: ${request.toJson()}');
    late List<Announcement> announcements;
    try {
      announcements = await _iapApi.getAnnouncements(request);
      for (final announcement in announcements) {
        final localAnnouncement =
            AnnouncementLocal.fromAnnouncement(announcement);
        await _announcementStore.save(
            localAnnouncement, localAnnouncement.announcementContentId);
      }
      await _configurationService
          .setLastPullAnnouncementTime(DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      log.info('Error fetching announcements: $e');
      return [];
    }
    log.info('Fetched announcements: ${announcements.length}');
    return announcements;
  }

  @override
  List<AnnouncementLocal> getLocalAnnouncements() {
    final announcements = _announcementStore.getAll()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return announcements;
  }

  @override
  Future<void> markAsRead(String? announcementContentId) async {
    if (announcementContentId == null) {
      return;
    }
    final announcement = _announcementStore.get(announcementContentId);
    if (announcement != null) {
      announcement.markAsRead();
      await _announcementStore.save(announcement, announcementContentId);
    }
  }

  @override
  List<AnnouncementLocal> getUnreadAnnouncements() {
    final allAnnouncements = getLocalAnnouncements();
    return allAnnouncements.where((element) => !element.read).toList();
  }

  @override
  AnnouncementLocal? getAnnouncement(String? announcementContentId) {
    if (announcementContentId == null) {
      return null;
    }
    return _announcementStore.get(announcementContentId);
  }

  @override
  AnnouncementLocal? getOldestAnnouncement() {
    final announcements = getUnreadAnnouncements();
    return announcements.firstOrNull;
  }

  @override
  Future<void> showOldestAnnouncement({bool shouldRepeat = true}) async {
    final announcement = getOldestAnnouncement();
    if (announcement != null) {
      final context = injector<NavigationService>().context;
      final additionalData =
          AdditionalData.fromJson(announcement.additionalData);

      /// If the announcement is expired, mark it as read and show the next one
      if (announcement.isExpired) {
        injector<MetricClientService>().addEvent(
          MixpanelEvent.expiredBeforeViewing,
          data: {
            MixpanelProp.notificationId: announcement.announcementContentId,
            MixpanelProp.channel: 'in-app',
          },
        );
        await markAsRead(announcement.announcementContentId);
        if (shouldRepeat) {
          await showOldestAnnouncement();
        }
        return;
      }
      await showNotifications(context, announcement.announcementContentId,
          body: announcement.content,
          handler: additionalData.isTappable
              ? () async {
                  await additionalData.handleTap(
                    context,
                    injector<NavigationService>().pageController,
                  );
                }
              : null, callBackOnDismiss: () async {
        if (shouldRepeat) {
          await showOldestAnnouncement();
        }
      });
    }
  }
}
