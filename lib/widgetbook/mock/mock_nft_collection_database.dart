import 'package:autonomy_flutter/nft_collection/database/nft_collection_database.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/address_collection_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/asset_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/provenance_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/token_dao.dart';
import 'package:autonomy_flutter/nft_collection/models/address_collection.dart';
import 'package:autonomy_flutter/nft_collection/models/asset.dart';
import 'package:autonomy_flutter/nft_collection/models/provenance.dart';
import 'package:autonomy_flutter/nft_collection/models/token.dart';

class MockNftCollectionDatabase extends NftCollectionDatabase {
  MockNftCollectionDatabase() : super();

  @override
  AddressCollectionDao get addressCollectionDao => MockAddressCollectionDao();

  @override
  AssetDao get assetDao => MockAssetDao();

  @override
  ProvenanceDao get provenanceDao => MockProvenanceDao();

  @override
  TokenDao get tokenDao => MockTokenDao();
}

class MockAddressCollectionDao extends AddressCollectionDao {
  @override
  Future<void> insertAddressesAbort(List<AddressCollection> addresses) async {}

  @override
  Future<void> deleteAddresses(List<String> addresses) async {}

  @override
  Future<List<AddressCollection>> findAllAddresses() async {
    return [];
  }

  @override
  Future<List<String>> findAddressesIsHidden(bool isHidden) async {
    return [];
  }

  @override
  Future<void> setAddressIsHidden(
      List<String> addresses, bool isHidden) async {}

  @override
  Future<void> updateRefreshTime(List<String> addresses, int time) async {}

  @override
  Future<void> deleteAddress(AddressCollection address) async {}

  @override
  Future<List<AddressCollection>> findAddresses(List<String> addresses) async {
    return [];
  }

  @override
  Future<void> insertAddresses(List<AddressCollection> addresses) async {}

  @override
  Future<void> removeAll() async {}

  @override
  Future<void> updateAddresses(List<AddressCollection> addresses) async {}
}

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

class MockTokenDao extends TokenDao {
  @override
  Future<void> insertTokens(List<Token> tokens) async {}

  @override
  Future<void> deleteTokens(List<String> tokenIds) async {}

  @override
  Future<List<Token>> findAllTokens() async {
    return [];
  }

  @override
  Future<void> deleteTokenByID(String tokenID) async {}

  @override
  Future<void> deleteTokensByOwners(List<String> owners) async {}

  @override
  Future<List<Token>> findAllPendingTokens() async {
    return [];
  }

  @override
  Future<List<String>> findAllTokenIDs() async {
    return [];
  }

  @override
  Future<List<Token>> findAllTokensByOwners(List<String> owners) async {
    return [];
  }

  @override
  Future<List<Token>> findAllTokensByTokenIDs(List<String> tokenIDs) async {
    return [];
  }

  @override
  Future<void> insertToken(Token token) async {}

  @override
  Future<void> removeAll() async {}

  @override
  Future<List<String>> findTokenIDsByOwners(List<String> owners) async {
    return [];
  }

  @override
  Future<List<String>> findTokenIDsOwnersOwn(List<String> owners) async {
    return [];
  }

  @override
  Future<List<Token>> findTokensByID(String tokenID) async {
    return [];
  }

  @override
  Future<void> insertTokensAbort(List<Token> tokens) async {}
}
