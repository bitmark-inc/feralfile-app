import 'package:flutter/services.dart';

class RangeTextInputFormatter extends TextInputFormatter {
  final int? min;
  final int? max;

  RangeTextInputFormatter({
    required this.min,
    required this.max,
  });

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final int intValue = int.tryParse(newValue.text) ?? 0;
    if (min != null && intValue < min!) {
      return TextEditingValue(text: min.toString());
    }
    if (max != null && intValue > max!) {
      return TextEditingValue(text: max.toString());
    }
    return newValue;
  }
}
