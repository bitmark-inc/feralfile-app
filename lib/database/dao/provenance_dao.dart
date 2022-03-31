import 'package:autonomy_flutter/model/provenance.dart';
import 'package:floor/floor.dart';

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
