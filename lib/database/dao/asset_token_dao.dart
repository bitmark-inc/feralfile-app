import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:floor/floor.dart';

@dao
abstract class AssetTokenDao {
  @Query('SELECT * FROM AssetToken ORDER BY lastActivityTime DESC')
  Future<List<AssetToken>> findAllAssetTokens();

  @Query(
      'SELECT * FROM AssetToken WHERE ownerAddress NOT IN (:owners) ORDER BY lastActivityTime DESC')
  Future<List<AssetToken>> findAllAssetTokensWhereNot(List<String> owners);

  @Query('SELECT * FROM AssetToken WHERE blockchain = :blockchain')
  Future<List<AssetToken>> findAssetTokensByBlockchain(String blockchain);

  @Query('SELECT * FROM AssetToken WHERE id = :id')
  Future<AssetToken?> findAssetTokenById(String id);

  @Query('SELECT id FROM AssetToken')
  Future<List<String>> findAllAssetTokenIDs();

  @insert
  Future<void> insertAsset(AssetToken asset);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAssets(List<AssetToken> assets);

  @delete
  Future<void> deleteAsset(AssetToken asset);

  @Query('DELETE FROM AssetToken WHERE id NOT IN (:ids)')
  Future<void> deleteAssetsNotIn(List<String> ids);

  @Query('DELETE FROM AssetToken WHERE ownerAddress NOT IN (:owners)')
  Future<void> deleteAssetsNotBelongs(List<String> owners);

  @Query('DELETE FROM AssetToken')
  Future<void> removeAll();
}

/** MARK: - Important!
*** Because of limitation of Floor, please override this in auto-generated app_database.g.dart

 @override
Future<List<String>> findAllAssetTokenIDs() async {
  return _queryAdapter.queryList('SELECT id FROM AssetToken',
      mapper: (Map<String, Object?> row) => row['id'] as String);
}
 */