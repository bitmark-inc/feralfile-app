import 'package:autonomy_flutter/util/constants.dart';
import 'package:nft_collection/models/asset_token.dart';

extension AssetTokenExtension on List<AssetToken> {
  void sortToken() {
    sort((a, b) {
      final aSource = a.source?.toLowerCase() ?? INDEXER_UNKNOWN_SOURCE;
      final bSource = b.source?.toLowerCase() ?? INDEXER_UNKNOWN_SOURCE;

      if (aSource == INDEXER_UNKNOWN_SOURCE &&
          bSource == INDEXER_UNKNOWN_SOURCE) {
        return b.lastUpdateTime.compareTo(a.lastUpdateTime);
      }

      if (aSource == INDEXER_UNKNOWN_SOURCE) return 1;
      if (bSource == INDEXER_UNKNOWN_SOURCE) return -1;

      return b.lastUpdateTime.compareTo(a.lastUpdateTime);
    });
  }
}
