import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MockLocalization {
  static Widget wrapWithLocalization({required Widget child}) {
    return EasyLocalization(
      supportedLocales: const [Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      useFallbackTranslations: true,
      child: child,
    );
  }
}
