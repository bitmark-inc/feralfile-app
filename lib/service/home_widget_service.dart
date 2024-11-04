import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/encrypt_env/secrets.g.dart';
import 'package:autonomy_flutter/model/dailies.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/indexer_service.dart';

class HomeWidgetService {
  final String appGroupId = 'com.bitmark.autonomy_flutter';
  final String androidWidgetName = 'FeralfileDaily';
  final String iosWidgetName = 'iosWidgetName'; // TODO: Update this value

  Future<void> init() async {
    await HomeWidget.setAppGroupId(appGroupId);
    HomeWidget.widgetClicked.listen((widgetName) {
      log.info('[HomeWidgetService] Widget clicked: $widgetName');
    });
  }

  Future<void> updateWidget(
      {required Map<String, dynamic> data, bool shouldUpdate = true}) async {
    data.forEach((key, value) {
      HomeWidget.saveWidgetData(key, value);
    });
    if (shouldUpdate) {
      await HomeWidget.updateWidget(
          name: androidWidgetName,
          androidName: androidWidgetName,
          qualifiedAndroidName:
              'com.bitmark.autonomy_flutter.$androidWidgetName',
          iOSName: iosWidgetName);
    }
  }

  Future<void> setDailyTokenToHomeWidget(AssetToken assetToken) async {
    final artistName = assetToken.artistName;
    final title = assetToken.displayTitle;
    final medium = assetToken.medium;
    final thumbnail = assetToken.galleryThumbnailURL;
    // call http get to get image data from thumbnail
    if (thumbnail != null) {
      final res = await http.get(Uri.parse(thumbnail));
      final imageData = res.bodyBytes;
      // convert to hex base 64
      final base64ImageData = base64Encode(imageData);
      final now = DateTime.now();
      final sixHoursAgo = now.subtract(Duration(hours: 6));
      // get only date from six hours ago
      final key = DateTime(sixHoursAgo.year, sixHoursAgo.month, sixHoursAgo.day)
          .millisecondsSinceEpoch;
      final data = {
        key.toString(): jsonEncode({
          'artistName': artistName,
          'title': title,
          'medium': medium,
          'base64ImageData': base64ImageData,
        })
      };
      // await updateWidget(data: data);
    }
  }

  Future<void> updateDailyTokensToHomeWidget() async {
    await getSecretEnv();
    await dotenv.load();
    await setupHomeWidgetInjector();

    final listDailies =
        await injector<FeralFileService>().getUpcomingDailyTokens(limit: 6);

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

    // Format all daily tokens and combine their data
    final Map<String, dynamic> combinedData = {};
    for (final dailyToken in filteredDailies) {
      final data = await _formatDailyTokenData(dailyToken);
      if (data != null) {
        combinedData.addAll(data);
      }
    }

    print('callbackDispatcher combinedData: $combinedData');

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
      final thumbnail = token.galleryThumbnailURL;

      String? base64ImageData;
      if (thumbnail != null) {
        final res = await http.get(Uri.parse(thumbnail));
        final imageData = res.bodyBytes;
        // convert to hex base 64
        base64ImageData = base64Encode(imageData);
      }

      String? base64MediumIcon;
      if (['video', 'software'].contains(medium)) {
        // final ByteData data =
        //     await rootBundle.load('assets/images/widget_medium_icon.svg');
        // final List<int> bytes = data.buffer.asUint8List();
        // base64MediumIcon = base64Encode(bytes);
      }

      print('base64MediumIcon: $base64MediumIcon');
      final data = {
        dailyToken.displayTime.millisecondsSinceEpoch.toString(): jsonEncode({
          'artistName': artistName,
          'title': title,
          'base64MediumIcon': base64MediumIcon ?? '',
          'base64ImageData': base64ImageData,
        })
      };

      return data;
    } catch (e) {
      print('Error in _formatDailyTokenData: $e');
      return null;
    }
  }
}
