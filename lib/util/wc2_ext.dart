extension Wc2Extension on String {
  // https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md
  String get caip2Namespace => split(':')[0];
}
