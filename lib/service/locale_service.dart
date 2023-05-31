import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class LocaleService {
  static const MethodChannel _channel = MethodChannel('locale');
  static String _measurementSystem = "metric";

  static String get measurementSystem => _measurementSystem;

  static Future<void> refresh(BuildContext context) async {
    String? localeMeasurement;
    if (Platform.isIOS) {
      final res = await _channel.invokeMethod('getMeasurementSystem');
      localeMeasurement = res["data"];
    } else {
      final locale = Localizations.localeOf(context);
      localeMeasurement = locale.countryCode;
    }
    if (localeMeasurement == null) {
      _measurementSystem = "metric";
    } else {
      localeMeasurement = localeMeasurement.toLowerCase();
      if (localeMeasurement.contains("us") ||
          localeMeasurement.contains("lr") ||
          localeMeasurement.contains("mm")) {
        _measurementSystem = "imperial";
      } else {
        _measurementSystem = "metric";
      }
    }
  }
}
