import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/additional_data/additional_data.dart';
import 'package:autonomy_flutter/model/dailies.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_bloc.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_page.dart';
import 'package:autonomy_flutter/screen/feralfile_series/feralfile_series_page.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

enum DailyNotificationType {
  viewDaily,
  revisitDaily,
  viewDailySeries,
  viewDailyExhibition,
  meetDailyArtist,
  displayDailyOnTV,
  ;

  static DailyNotificationType? fromString(String value) {
    switch (value) {
      case 'view_daily':
        return DailyNotificationType.viewDaily;
      case 'revisit_daily':
        return DailyNotificationType.revisitDaily;
      case 'view_daily_series':
        return DailyNotificationType.viewDailySeries;
      case 'view_daily_exhibition':
        return DailyNotificationType.viewDailyExhibition;
      case 'meet_daily_artist':
        return DailyNotificationType.meetDailyArtist;
      case 'display_daily_on_tv':
        return DailyNotificationType.displayDailyOnTV;
      default:
        log.info('DailyNotificationType: fromString: unknown value: $value');
        return null;
    }
  }
}

class DailyNotificationData extends AdditionalData {
  final DailyNotificationType dailyNotificationType;

  final _navigationService = injector<NavigationService>();
  final _feralFileService = injector<FeralFileService>();
  final _dailyWorkBloc = injector<DailyWorkBloc>();

  DailyNotificationData({
    required this.dailyNotificationType,
    required super.notificationType,
    super.announcementContentId,
    super.linkText,
  });

  @override
  bool get isTappable => true;

  @override
  Future<void> handleTap(BuildContext context) async {
    log.info('DailyNotificationData: handle tap');
    bool isDailyTokenAvailable = await prepareAndDidSuccess();
    if (!isDailyTokenAvailable) {
      _logAndSendSentryForNullData('dailyToken');
      return;
    }
    final dailyToken = _dailyWorkBloc.state.currentDailyToken;
    switch (dailyNotificationType) {
      case DailyNotificationType.viewDaily:
      case DailyNotificationType.revisitDaily:
        await _navigationService.navigatePath(AppRouter.dailyWorkPage);
      case DailyNotificationType.viewDailySeries:
        final artwork = dailyToken!.artwork;
        if (artwork == null) {
          _logAndSendSentryForNullData('artwork');
          return;
        }
        final series = await _feralFileService.getSeries(artwork.seriesID);
        if (!context.mounted) {
          return;
        }
        await Navigator.of(context).pushNamed(
          AppRouter.feralFileSeriesPage,
          arguments: FeralFileSeriesPagePayload(
            seriesId: artwork.seriesID,
            exhibitionId: series.exhibitionID,
          ),
        );
      case DailyNotificationType.viewDailyExhibition:
        final artwork = dailyToken!.artwork;
        if (artwork == null) {
          _logAndSendSentryForNullData('artwork');
          return;
        }
        final series = await _feralFileService.getSeries(artwork.seriesID);
        final exhibition = series.exhibition;
        if (exhibition == null) {
          _logAndSendSentryForNullData('exhibition');
          return;
        }
        if (!context.mounted) {
          return;
        }
        await Navigator.of(context).pushNamed(
          AppRouter.exhibitionDetailPage,
          arguments:
              ExhibitionDetailPayload(exhibitions: [exhibition], index: 0),
        );
      case DailyNotificationType.meetDailyArtist:
        final artistID = _dailyWorkBloc.state.assetTokens.firstOrNull?.artistID;

        if (artistID == null) {
          _logAndSendSentryForNullData('artistID');
          return;
        }
        await injector<NavigationService>().openFeralFileArtistPage(artistID);
      case DailyNotificationType.displayDailyOnTV:
        await _navigationService.navigatePath(AppRouter.dailyWorkPage);
        await Future.delayed(const Duration(milliseconds: 300), () {
          dailyWorkKey.currentState?.openDisplayDialog();
        });

      default:
    }
  }

  void _logAndSendSentryForNullData(String data) {
    log.warning('DailyNotificationData: $data is null');
    unawaited(Sentry.captureMessage('DailyNotificationData: $data is null'));
  }

  @override
  Future<bool> prepareAndDidSuccess() async {
    DailyToken? dailyToken = _dailyWorkBloc.state.currentDailyToken;
    if (dailyToken == null) {
      log.warning('DailyNotificationData: dailyToken is null, retrying');
      await Future.delayed(const Duration(milliseconds: 1000));
      dailyToken = _dailyWorkBloc.state.currentDailyToken;
    }
    if (dailyToken == null) {
      log.warning('DailyNotificationData: dailyToken is null');
      unawaited(
          Sentry.captureMessage('DailyNotificationData: dailyToken is null'));
      return false;
    }
    return true;
  }
}
