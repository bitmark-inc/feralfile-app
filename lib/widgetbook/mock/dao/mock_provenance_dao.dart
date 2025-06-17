import 'package:autonomy_flutter/nft_collection/database/dao/dao.dart';
import 'package:autonomy_flutter/nft_collection/models/models.dart';

class MockProvenanceDao extends ProvenanceDao {
  @override
  Future<void> insertProvenances(List<Provenance> provenances) async {}

  @override
  Future<void> deleteProvenances(List<String> provenanceIds) async {}

  @override
  Future<List<Provenance>> findAllProvenances() async {
    return [];
  }

  @override
  Future<void> deleteProvenanceNotBelongs(List<String> tokenIDs) async {}

  @override
  Future<List<Provenance>> findProvenanceByTokenID(String tokenID) async {
    return [];
  }

  @override
  Future<void> insertProvenance(List<Provenance> provenances) async {}

  @override
  Future<void> removeAll() async {}
}
