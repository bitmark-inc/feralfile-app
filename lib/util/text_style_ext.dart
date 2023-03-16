import 'package:flutter/material.dart';

extension TextStyle_ext on TextStyle {
  TextStyle addStyle(TextStyle? style) {
    return copyWith(fontSize: fontSize! + (style?.fontSize ?? 0.0));
  }
}
