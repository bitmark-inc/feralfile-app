import 'package:nft_collection/models/album_model.dart';

extension AlbumModelListExt on List<AlbumModel> {
  List<AlbumModel> filterByName(String name) {
    return where((element) => element.name?.contains(name) ?? false).toList();
  }
}
