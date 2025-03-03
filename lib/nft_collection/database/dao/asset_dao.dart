//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:floor/floor.dart';
import 'package:autonomy_flutter/nft_collection/models/asset.dart';

@dao
abstract class AssetDao {
  @Query('SELECT * FROM Asset')
  Future<List<Asset>> findAllAssets();

  @Query('SELECT * FROM Asset WHERE indexID IN (:indexIDs)')
  Future<List<Asset>> findAllAssetsByIndexIDs(List<String> indexIDs);

  @Query('SELECT indexID FROM Asset')
  Future<List<String>> findAllIndexIDs();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAsset(Asset token);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAssets(List<Asset> assets);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertAssetsAbort(List<Asset> assets);

  @update
  Future<void> updateAsset(Asset asset);

  @Query('DELETE FROM Asset WHERE indexID = (:indexID)')
  Future<void> deleteAssetByIndexID(String indexID);

  @Query('DELETE FROM Asset')
  Future<void> removeAll();
}
