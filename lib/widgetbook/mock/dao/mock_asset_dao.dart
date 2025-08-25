import 'package:autonomy_flutter/nft_collection/database/dao/asset_dao.dart';
import 'package:autonomy_flutter/nft_collection/models/models.dart';

class MockAssetDao extends AssetDao {
  @override
  Future<void> insertAssets(List<Asset> assets) async {}

  @override
  Future<void> deleteAssets(List<String> assetIds) async {}

  @override
  Future<List<Asset>> findAllAssets() async {
    return [];
  }

  @override
  Future<void> deleteAssetByIndexID(String indexID) async {}

  @override
  Future<List<Asset>> findAllAssetsByIndexIDs(List<String> indexIDs) async {
    return [];
  }

  @override
  Future<List<String>> findAllIndexIDs() async {
    return [];
  }

  @override
  Future<void> insertAsset(Asset asset) async {}

  @override
  Future<void> removeAll() async {}

  @override
  Future<void> insertAssetsAbort(List<Asset> assets) async {}

  @override
  Future<void> updateAsset(Asset asset) async {}
}
