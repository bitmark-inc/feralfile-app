extension WalletConnectExt on String {
  bool get isAutonomyConnectUri {
    if (!startsWith('wc:')) {
      return false;
    }
    try {
      // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1328.md
      final uri = Uri.parse(this);
      final version = int.parse(uri.path.split('@')[1]);
      return version == 2;
    } catch (e) {
      return false;
    }
  }
}
