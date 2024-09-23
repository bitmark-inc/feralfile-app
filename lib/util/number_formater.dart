class OrdinalNumberFormatter {
  String format(int number) {
    String suffix = 'th';
    switch (number % 10) {
      case 1:
        if (number % 100 != 11) {
          suffix = 'st';
        }
      case 2:
        if (number % 100 != 12) {
          suffix = 'nd';
        }
      case 3:
        if (number % 100 != 13) {
          suffix = 'rd';
        }
      default:
        suffix = 'th';
    }
    return '$number$suffix';
  }
}
