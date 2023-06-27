import 'dart:math';

import 'package:flutter/material.dart';

extension TextStyleExtension on TextStyle {
  static const double _minFontSize = 8.0;

  TextStyle adjustSize(double size) {
    return copyWith(fontSize: max(fontSize! + size, _minFontSize));
  }
}
