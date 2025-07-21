import 'package:autonomy_flutter/nft_collection/database/dao/predefined_collection_dao.dart';
import 'package:autonomy_flutter/nft_collection/models/predefined_collection_model.dart';

class MockPredefinedCollectionDao implements PredefinedCollectionDao {
  @override
  Future<List<PredefinedCollectionModel>> getPredefinedCollectionsByArtist(
      {String name = ""}) {
    return Future.value([
      PredefinedCollectionModel(
          id: "1",
          name: "Artist A",
          total: 10,
          thumbnailURL: "https://example.com/artist_a.jpg"),
      PredefinedCollectionModel(
          id: "2",
          name: "Artist B",
          total: 5,
          thumbnailURL: "https://example.com/artist_b.jpg"),
    ]);
  }

  @override
  Future<List<PredefinedCollectionModel>> getPredefinedCollectionsByMedium(
      {String title = "",
      required List<String> mimeTypes,
      required List<String> mediums,
      bool isInMimeTypes = true}) {
    return Future.value([
      PredefinedCollectionModel(
          id: "1",
          name: "Medium A",
          total: 20,
          thumbnailURL: "https://example.com/medium_a.jpg"),
      PredefinedCollectionModel(
          id: "2",
          name: "Medium B",
          total: 15,
          thumbnailURL: "https://example.com/medium_b.jpg"),
    ]);
  }
}
