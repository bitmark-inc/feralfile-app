import 'package:autonomy_flutter/util/log.dart';
import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  final String appGroupId = 'group.com.autonomy';
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
          androidName: androidWidgetName, iOSName: iosWidgetName);
    }
  }
}
