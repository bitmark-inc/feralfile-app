class OrdinalNumberFormatter {
  String format(int number) {
    String suffix = "th";
    switch (number % 10) {
      case 1:
        if (number % 100 != 11) suffix = "st";
        break;
      case 2:
        if (number % 100 != 12) suffix = "nd";
        break;
      case 3:
        if (number % 100 != 13) suffix = "rd";
        break;
      default:
        suffix = "th";
    }
    return "$number$suffix";
  }
}
