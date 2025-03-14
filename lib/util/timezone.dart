import 'package:flutter_timezone/flutter_timezone.dart';

class TimezoneHelper {
  static Future<String> getTimeZone() async {
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    return currentTimeZone;
  }
}
