import 'package:autonomy_flutter/nft_collection/models/models.dart';
import 'package:collection/collection.dart';
import 'package:autonomy_flutter/widgetbook/mock_data/data/asset_token.dart';

class MockAssetToken {
  static List<AssetToken> all = assetTokenJsonList
      .map((json) => AssetToken.fromJsonGraphQl(json))
      .toList();

  static AssetToken? getByIndexerTokenId(String? indexerTokenId) {
    return all.firstWhereOrNull(
      (token) => token.id == indexerTokenId,
    );
  }
}
