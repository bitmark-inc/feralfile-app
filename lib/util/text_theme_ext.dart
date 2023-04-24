import 'package:autonomy_theme/style/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AppTheme {
  static const moMASans = "MoMASans";
}

extension TextThemeExtension on TextTheme {
  TextStyle get moMASans400Black16 {
    final bool isLightMode =
        SchedulerBinding.instance.window.platformBrightness == Brightness.light;
    return TextStyle(
      color: isLightMode ? AppColor.primaryBlack : AppColor.primaryBlack,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      fontFamily: AppTheme.moMASans,
      height: 1.4,
    );
  }

  TextStyle get moMASans400Black14 {
    final bool isLightMode =
        SchedulerBinding.instance.window.platformBrightness == Brightness.light;
    return TextStyle(
      color: isLightMode ? AppColor.primaryBlack : AppColor.primaryBlack,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      fontFamily: AppTheme.moMASans,
      height: 1.4,
    );
  }

  TextStyle get moMASans400Black12 {
    final bool isLightMode =
        SchedulerBinding.instance.window.platformBrightness == Brightness.light;
    return TextStyle(
      color: isLightMode ? AppColor.primaryBlack : AppColor.primaryBlack,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      fontFamily: AppTheme.moMASans,
      height: 1.4,
    );
  }

  TextStyle get moMASans400Black24 {
    final bool isLightMode =
        SchedulerBinding.instance.window.platformBrightness == Brightness.light;
    return TextStyle(
      color: isLightMode ? AppColor.primaryBlack : AppColor.primaryBlack,
      fontSize: 24,
      fontWeight: FontWeight.w400,
      fontFamily: AppTheme.moMASans,
      height: 1.4,
    );
  }

  TextStyle get moMASans700Black12 {
    final bool isLightMode =
        SchedulerBinding.instance.window.platformBrightness == Brightness.light;
    return TextStyle(
      color: isLightMode ? AppColor.primaryBlack : AppColor.primaryBlack,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      fontFamily: AppTheme.moMASans,
      height: 1.4,
    );
  }

  TextStyle get moMASans700Black14 {
    final bool isLightMode =
        SchedulerBinding.instance.window.platformBrightness == Brightness.light;
    return TextStyle(
      color: isLightMode ? AppColor.primaryBlack : AppColor.primaryBlack,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      fontFamily: AppTheme.moMASans,
      height: 1.4,
    );
  }

  TextStyle get moMASans700Black16 {
    final bool isLightMode =
        SchedulerBinding.instance.window.platformBrightness == Brightness.light;
    return TextStyle(
      color: isLightMode ? AppColor.primaryBlack : AppColor.primaryBlack,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      fontFamily: AppTheme.moMASans,
      height: 1.4,
    );
  }

  TextStyle get moMASans700Black24 {
    final bool isLightMode =
        SchedulerBinding.instance.window.platformBrightness == Brightness.light;
    return TextStyle(
      color: isLightMode ? AppColor.primaryBlack : AppColor.primaryBlack,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      fontFamily: AppTheme.moMASans,
      height: 1.4,
    );
  }

  TextStyle get moMASans400White12 {
    final bool isLightMode =
        SchedulerBinding.instance.window.platformBrightness == Brightness.light;
    return TextStyle(
      color: isLightMode ? AppColor.white : AppColor.white,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      fontFamily: AppTheme.moMASans,
      height: 1.4,
    );
  }

  TextStyle get moMASans400White14 {
    final bool isLightMode =
        SchedulerBinding.instance.window.platformBrightness == Brightness.light;
    return TextStyle(
      color: isLightMode ? AppColor.white : AppColor.white,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      fontFamily: AppTheme.moMASans,
      height: 1.4,
    );
  }

  TextStyle get moMASans400White16 {
    final bool isLightMode =
        SchedulerBinding.instance.window.platformBrightness == Brightness.light;
    return TextStyle(
      color: isLightMode ? AppColor.white : AppColor.white,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      fontFamily: AppTheme.moMASans,
      height: 1.4,
    );
  }

  TextStyle get moMASans400White24 {
    final bool isLightMode =
        SchedulerBinding.instance.window.platformBrightness == Brightness.light;
    return TextStyle(
      color: isLightMode ? AppColor.white : AppColor.white,
      fontSize: 24,
      fontWeight: FontWeight.w400,
      fontFamily: AppTheme.moMASans,
      height: 1.4,
    );
  }

  TextStyle get moMASans400Grey12 {
    final bool isLightMode =
        SchedulerBinding.instance.window.platformBrightness == Brightness.light;
    return TextStyle(
      color: isLightMode ? AppColor.disabledColor : AppColor.disabledColor,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      fontFamily: AppTheme.moMASans,
      height: 1.4,
    );
  }

  TextStyle get moMASans400Grey14 {
    final bool isLightMode =
        SchedulerBinding.instance.window.platformBrightness == Brightness.light;
    return TextStyle(
      color: isLightMode ? AppColor.disabledColor : AppColor.disabledColor,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      fontFamily: AppTheme.moMASans,
      height: 1.4,
    );
  }

  TextStyle get moMASans400Grey16 {
    final bool isLightMode =
        SchedulerBinding.instance.window.platformBrightness == Brightness.light;
    return TextStyle(
      color: isLightMode ? AppColor.disabledColor : AppColor.disabledColor,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      fontFamily: AppTheme.moMASans,
      height: 1.4,
    );
  }

  TextStyle get moMASans400Grey24 {
    final bool isLightMode =
        SchedulerBinding.instance.window.platformBrightness == Brightness.light;
    return TextStyle(
      color: isLightMode ? AppColor.disabledColor : AppColor.disabledColor,
      fontSize: 24,
      fontWeight: FontWeight.w400,
      fontFamily: AppTheme.moMASans,
      height: 1.4,
    );
  }
}
