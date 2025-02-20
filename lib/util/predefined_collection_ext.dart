import 'package:autonomy_flutter/nft_collection/models/asset_token.dart';
import 'package:autonomy_flutter/nft_collection/models/predefined_collection_model.dart';

extension PredefinedCollectionModelListExt on List<PredefinedCollectionModel> {
  List<PredefinedCollectionModel> filterByName(String name) =>
      where((element) =>
              element.name?.toLowerCase().contains(name.toLowerCase()) ?? false)
          .toList();
}

extension PredefinedCollectionModelExt on PredefinedCollectionModel {
  CompactedAssetToken get compactedAssetToken => CompactedAssetToken(
        id: id,
        balance: 1,
        owner: '',
        lastActivityTime: DateTime.now(),
        lastRefreshedTime: DateTime.now(),
        galleryThumbnailURL: thumbnailURL,
        edition: 0,
      );
}
