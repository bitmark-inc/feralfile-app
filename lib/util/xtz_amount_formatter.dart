class XtzAmountFormatter {
  final int amount;
  XtzAmountFormatter(this.amount);

  String format() {
    return "${amount/1000000}";
  }
}