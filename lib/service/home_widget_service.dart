import 'dart:convert';

import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:nft_collection/models/asset_token.dart';

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
      final dateTimeFormatter = DateFormat('yyyy-MM-dd');
      final data = {
        dateTimeFormatter.format(now): jsonEncode({
          'artistName': artistName,
          'title': title,
          'medium': medium,
          'base64ImageData': base64ImageData,
        })
      };
      await updateWidget(data: data);
    }
  }
}
