import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/dailies.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/services/indexer_service.dart';

class HomeWidgetService {
  final String iOSAppGroupId = 'group.com.bitmark.autonomywallet.storage';
  final String appId = 'com.bitmark.autonomy_flutter';
  final String androidWidgetName = 'FeralfileDaily';
  final String iosWidgetName = 'Daily_Widget';

  HomeWidgetService() {
    unawaited(init());
  }

  Future<void> init() async {
    await HomeWidget.setAppGroupId(iOSAppGroupId);
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
      final listDailies =
          await injector<FeralFileService>().getUpcomingDailyTokens();

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

      await _updateDailyTokensToHomeWidget(filteredDailies);
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
      }
    }

    log.info('callbackDispatcher combinedData: $combinedData');

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
        return null;
      }

      final token = assetTokens.first;
      final artistName = token.artistName;
      final title = token.displayTitle;
      final medium = token.medium;
      final isFeralFileToken = token.isFeralfile;
      final thumbnail = isFeralFileToken
          ? dailyToken.artwork!.dailyThumbnailURL
          : token.galleryThumbnailURL;

      String? base64ImageData;
      if (thumbnail != null) {
        final res = await http.get(Uri.parse(thumbnail));

        if (res.statusCode == 200) {
          Uint8List imageBytes = res.bodyBytes;
          base64ImageData = base64Encode(imageBytes);
        }
      }

      String? base64MediumIcon;
      if (['video', 'software'].contains(medium)) {
        final ByteData data =
            await rootBundle.load('assets/images/widget_medium_icon.png');
        final List<int> bytes = data.buffer.asUint8List();
        base64MediumIcon = base64Encode(bytes);
      }

      final data = {
        dailyToken.displayTime.millisecondsSinceEpoch.toString(): jsonEncode({
          'artistName': '$artistName',
          'title': title,
          'base64MediumIcon': base64MediumIcon ?? '',
          'base64ImageData': base64ImageData ?? '',
        })
      };

      return data;
    } catch (e) {
      log.info('Error in _formatDailyTokenData: $e');
      return null;
    }
  }
}
