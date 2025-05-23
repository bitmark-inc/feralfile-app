import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/dailies.dart';
import 'package:autonomy_flutter/nft_collection/graphql/model/get_list_tokens.dart';
import 'package:autonomy_flutter/nft_collection/services/indexer_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class HomeWidgetService {
  HomeWidgetService() {
    unawaited(init());
  }

  final String iOSAppGroupId = 'group.com.bitmark.autonomywallet.storage';
  final String appId = 'com.bitmark.autonomy_flutter';
  final String androidWidgetName = 'FeralfileDaily';
  final String iosWidgetName = 'Daily_Widget';

  Future<void> init() async {
    await HomeWidget.setAppGroupId(iOSAppGroupId);

    // Please note that you should call this
    // after you have setup the AppGroupId for iOS
    await HomeWidget.registerInteractivityCallback(interactiveCallback);
  }

  Future<bool> isWidgetAdded() async {
    try {
      final installedWidget = await HomeWidget.getInstalledWidgets();
      return installedWidget.any((widget) {
        if (Platform.isAndroid)
          return widget.androidClassName?.contains(androidWidgetName) ?? false;
        if (Platform.isIOS)
          return widget.iOSKind?.contains(iosWidgetName) ?? false;
        return false;
      });
    } catch (e) {
      log.info('Error in isWidgetAdded: $e');
      return false;
    }
  }

  Future<void> updateWidget(
      {required Map<String, String> data, bool shouldUpdate = true}) async {
    try {
      await Future.wait(
        data.entries
            .map((entry) => HomeWidget.saveWidgetData(entry.key, entry.value)),
      );
    } catch (e) {
      log.info('Error in saveWidgetData: $e');
    }

    if (shouldUpdate) {
      await HomeWidget.updateWidget(
          name: androidWidgetName,
          androidName: androidWidgetName,
          qualifiedAndroidName: '$appId.$androidWidgetName',
          iOSName: iosWidgetName);
    }
  }

  Future<void> updateDailyTokensToHomeWidget() async {
    try {
      final localDate = DateTime.now().toLocal();
      // Start of current local day, in UTC time (YYYY-MM-DD 00:00:000z)
      final startDateInUtc =
          DateTime.utc(localDate.year, localDate.month, localDate.day);
      log.info('startDateInUtc: ${startDateInUtc.toIso8601String()}');
      final listDailies = await injector<FeralFileService>()
          .getUpcomingDailyTokens(startDate: startDateInUtc.toIso8601String());

      // Filter out dailies that have the same date
      final filteredDailies = listDailies
          .fold<Map<String, DailyToken>>({}, (map, token) {
            final dateKey = token.displayTime.toIso8601String().split('T')[0];
            if (!map.containsKey(dateKey)) {
              map[dateKey] = token;
            }
            return map;
          })
          .values
          .toList();

      log.info('Filtered dailies: ${filteredDailies.length}');

      await _updateDailyTokensToHomeWidget(filteredDailies);
      log.info('Updated daily tokens to home widget');
    } catch (e) {
      log.info('Error in updateDailyTokensToHomeWidget: $e');
    }
  }

  Future<void> _updateDailyTokensToHomeWidget(
      List<DailyToken> dailyTokens) async {
    // Format all daily tokens and combine their data
    final Map<String, String> combinedData = {};
    for (final dailyToken in dailyTokens) {
      final data = await _formatDailyTokenData(dailyToken);
      if (data != null) {
        combinedData.addAll(data);
      } else {
        log.info('No data found for daily token: ${dailyToken.indexId}');
      }
    }

    // Update widget with combined data
    if (combinedData.isNotEmpty) {
      await updateWidget(data: combinedData);
    }
  }

  Future<Map<String, String>?> _formatDailyTokenData(
      DailyToken dailyToken) async {
    try {
      final assetTokens = await injector<IndexerService>()
          .getNftTokens(QueryListTokensRequest(ids: [dailyToken.indexId]));
      if (assetTokens.isEmpty) {
        log.info(
            'No asset tokens found for daily token: ${dailyToken.indexId}');
        return null;
      }

      final token = assetTokens.first;
      final artistName = token.artistName;
      final title = token.displayTitle;
      final medium = token.medium;
      final isFeralFileToken = token.isFeralfile;
      final thumbnailUrl = isFeralFileToken
          ? dailyToken.artwork!.thumbnailURL
          : token.galleryThumbnailURL;
      final smallThumbnailUrl = isFeralFileToken
          ? dailyToken.artwork!.smallThumbnailURL
          : token.galleryThumbnailURL;

      String? base64ImageData;
      if (thumbnailUrl != null) {
        base64ImageData = await getBase64ImageData(thumbnailUrl);
      }

      String? base64SmallImageData;
      if (smallThumbnailUrl != null) {
        base64SmallImageData = await getBase64ImageData(smallThumbnailUrl);
      }

      String? base64MediumIcon;
      final iconData =
          await rootBundle.load('assets/images/widget_medium_icon.png');
      final List<int> bytes = iconData.buffer.asUint8List();
      base64MediumIcon = base64Encode(bytes);

      final dateKey = DateFormat('yyyy-MM-dd').format(dailyToken.displayTime);

      final data = {
        dateKey: jsonEncode({
          'artistName': '$artistName',
          'title': title,
          'base64MediumIcon': base64MediumIcon ?? '',
          'base64ImageData': base64ImageData ?? '',
          'base64SmallImageData': base64SmallImageData ?? '',
        })
      };

      return data;
    } catch (e) {
      log.info('Error in _formatDailyTokenData: $e');
      return null;
    }
  }

  Future<String?> getBase64ImageData(String imageUrl) async {
    final res = await http.get(Uri.parse(imageUrl));

    if (res.statusCode == 200) {
      final imageBytes = res.bodyBytes;
      return base64Encode(imageBytes);
    }

    return null;
  }
}

@pragma('vm:entry-point')
Future<void> interactiveCallback(Uri? uri) async {
  // We check the host of the uri to determine which action should be triggered.
  log.info('[Daily Widget] interactiveCallback: $uri');
}
