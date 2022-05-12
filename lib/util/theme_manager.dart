import 'package:autonomy_flutter/util/style.dart';
import 'package:flutter/material.dart';

enum AppTheme { mainTheme, sheetTheme, markdownTheme, markdownThemeBlack }

class AuThemeManager {
  ThemeData getThemeData(AppTheme theme) {
    switch (theme) {
      case AppTheme.mainTheme:
        return mainTheme;
      case AppTheme.markdownTheme:
        return markdownTheme;
      case AppTheme.markdownThemeBlack:
        return markdownThemeBlack;
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
    disabledColor: Color(0xFF999999),
    textTheme: ThemeData.light().textTheme.copyWith(
          headline1: appTextTheme.headline1?.copyWith(color: Colors.white),
          headline2: appTextTheme.headline2?.copyWith(color: Colors.white),
          headline3: appTextTheme.headline3?.copyWith(color: Colors.white),
          headline4: appTextTheme.headline4?.copyWith(color: Colors.white),
          headline5: appTextTheme.headline5?.copyWith(color: Colors.white),
          bodyText1: appTextTheme.bodyText1?.copyWith(color: Colors.white),
          bodyText2: appTextTheme.bodyText2?.copyWith(color: Colors.white),
          button: appTextTheme.bodyText2?.copyWith(color: Colors.white),
          caption: appTextTheme.caption?.copyWith(color: Colors.white),
        ),
  );

  final ThemeData markdownTheme = ThemeData(
      backgroundColor: Colors.black,
      primaryColor: Colors.white,
      textTheme: ThemeData.dark().textTheme.copyWith(
          bodyText2: appTextTheme.bodyText1?.copyWith(color: Colors.white)));

  final ThemeData markdownThemeBlack = ThemeData(
      backgroundColor: Colors.black,
      primaryColor: Colors.white,
      textTheme: ThemeData.dark().textTheme.copyWith(
          bodyText2: appTextTheme.bodyText1?.copyWith(color: Colors.black)));
}
