import 'dart:io';

class TimezoneHelper {
  static String getTimeZone() {
    String timezone = (Platform.isAndroid)
        ? _getAndroidTimezone()
        : (Platform.isIOS)
            ? _getIOSTimezone()
            : "";
    return timezone;
  }

  static String _getAndroidTimezone() {
    try {
      final result = Process.runSync("getprop", ["persist.sys.timezone"]);
      return result.stdout.toString().trim();
    } catch (e) {
      return "";
    }
  }

  static String _getIOSTimezone() {
    try {
      final result = Process.runSync("systemsetup", ["-gettimezone"]);
      return result.stdout.toString().trim().replaceAll("Time Zone: ", "");
    } catch (e) {
      return "";
    }
  }
}
