import 'dart:ui';

extension LocaleExt on Locale {
  /// Returns the language code of the locale.
  String get localeCode =>
      countryCode == null ? languageCode : '${languageCode}_$countryCode';
}
