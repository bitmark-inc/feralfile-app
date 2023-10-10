import 'package:nft_collection/models/album_model.dart';
import 'package:nft_collection/models/asset_token.dart';

extension AlbumModelListExt on List<AlbumModel> {
  List<AlbumModel> filterByName(String name) {
    return where((element) => element.name?.contains(name) ?? false).toList();
  }
}

extension AlbumModelExt on AlbumModel {
  CompactedAssetToken get compactedAssetToken {
    return CompactedAssetToken(
      id: this.id,
      balance: 1,
      owner: "",
      lastActivityTime: DateTime.now(),
      lastRefreshedTime: DateTime.now(),
      galleryThumbnailURL: this.thumbnailURL,
    );
  }
}
