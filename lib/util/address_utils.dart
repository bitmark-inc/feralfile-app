import 'constants.dart';

String addressURL(String address, CryptoType cryptoType) {
  switch (cryptoType) {
    case CryptoType.ETH:
      return "$etherScanUrl/address/$address";
    case CryptoType.XTZ:
      return "https://tzkt.io/$address/operations";
    case CryptoType.USDC:
      return "$etherScanUrl/token/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48?a=$address";
    default:
      return "";
  }
}
