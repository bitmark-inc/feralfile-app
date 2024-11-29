import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class LocaleService {
  static const MethodChannel _channel = MethodChannel('locale');
  static String _measurementSystem = 'metric';

  static String get measurementSystem => _measurementSystem;

  static Future<void> refresh(Locale locale) async {
    String? localeMeasurement;
    if (Platform.isIOS) {
      final res = await _channel.invokeMethod('getMeasurementSystem');
      if (res['data'] != null) {
        localeMeasurement = res['data'] as String;
      } else {
        localeMeasurement = _getCountryCode(locale);
      }
    } else {
      localeMeasurement = _getCountryCode(locale);
    }
    if (localeMeasurement == null) {
      _measurementSystem = 'metric';
    } else {
      localeMeasurement = localeMeasurement.toLowerCase();
      if (localeMeasurement.contains('us') ||
          localeMeasurement.contains('lr') ||
          localeMeasurement.contains('mm')) {
        _measurementSystem = 'imperial';
      } else {
        _measurementSystem = 'metric';
      }
    }
  }

  static String? _getCountryCode(Locale locale) => locale.countryCode;
}
