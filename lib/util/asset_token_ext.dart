import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';

extension AssetTokenExtension on AssetToken {
  static final Map<String, Map<String, String>> _tokenUrlMap = {
    "MAIN": {
      "ethereum": "https://etherscan.io/token/{contract}?a={tokenId}",
      "tezos": "https://tzkt.io/{contract}/tokens/{tokenId}/transfers"
    },
    "TEST": {
      "ethereum": "https://rinkeby.etherscan.io/token/{contract}?a={tokenId}",
      "tezos": "https://tzkt.io/{contract}/tokens/{tokenId}/transfers"
    }
  };

  String? get tokenURL {
    final network = Environment.appTestnetConfig ? "TEST" : "MAIN";
    final url = _tokenUrlMap[network]?[blockchain]
        ?.replaceAll("{tokenId}", tokenId ?? "")
        .replaceAll("{contract}", contractAddress ?? "");
    return url;
  }
}
