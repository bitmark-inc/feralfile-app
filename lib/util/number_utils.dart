extension DoubleExtension on double {
  double floorAtDigit(int digit) {
    return double.parse(toStringAsFixed(digit));
  }
}
