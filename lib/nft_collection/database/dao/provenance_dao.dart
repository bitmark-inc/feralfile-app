//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:floor/floor.dart';
import 'package:autonomy_flutter/nft_collection/models/provenance.dart';

@dao
abstract class ProvenanceDao {
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertProvenance(List<Provenance> provenance);

  @Query('SELECT * FROM Provenance WHERE tokenID = :tokenID')
  Future<List<Provenance>> findProvenanceByTokenID(String tokenID);

  @Query('DELETE FROM Provenance WHERE tokenID NOT IN (:tokenIDs)')
  Future<void> deleteProvenanceNotBelongs(List<String> tokenIDs);

  @Query('DELETE FROM Provenance')
  Future<void> removeAll();
}
