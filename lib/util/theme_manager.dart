import 'package:autonomy_flutter/util/style.dart';
import 'package:flutter/material.dart';

enum AppTheme { mainTheme, sheetTheme }

class AuThemeManager {
  ThemeData getThemeData(AppTheme theme) {
    switch (theme) {
      case AppTheme.mainTheme:
        return mainTheme;
      default:
        return sheetTheme;
    }
  }

  final ThemeData mainTheme = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    primarySwatch: Colors.grey,
    secondaryHeaderColor: Color(0xFF6D6B6B),
    errorColor: Color(0xFFA1200A),
    textTheme: appTextTheme,
  );

  final ThemeData sheetTheme = ThemeData(
      backgroundColor: Colors.black,
      primaryColor: Colors.white,
      textTheme: ThemeData.light().textTheme.copyWith(
            headline1: appTextTheme.headline1?.copyWith(color: Colors.white),
            bodyText1: appTextTheme.bodyText1?.copyWith(color: Colors.white),
          ));
}
