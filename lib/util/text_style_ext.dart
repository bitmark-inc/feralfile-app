import 'package:flutter/material.dart';

extension TextStyleExtension on TextStyle {
  TextStyle adjustSize(double size) {
    return copyWith(fontSize: fontSize! + size);
  }
}
