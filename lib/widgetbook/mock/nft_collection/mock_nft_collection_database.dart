import 'package:autonomy_flutter/nft_collection/database/dao/address_collection_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/asset_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/provenance_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/token_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/nft_collection_database.dart';
import 'package:autonomy_flutter/widgetbook/mock/dao/mock_address_collection_dao.dart';
import 'package:autonomy_flutter/widgetbook/mock/dao/mock_asset_dao.dart';
import 'package:autonomy_flutter/widgetbook/mock/dao/mock_asset_token_dao.dart';
import 'package:autonomy_flutter/widgetbook/mock/dao/mock_provenance_dao.dart';
import 'package:autonomy_flutter/widgetbook/mock/dao/mock_token_dao.dart';

class MockNftCollectionDatabase extends NftCollectionDatabase {
  MockNftCollectionDatabase() : super();

  @override
  AddressCollectionDao get addressCollectionDao => MockAddressCollectionDao();

  @override
  AssetDao get assetDao => MockAssetDao();

  @override
  AssetTokenDao get assetTokenDao => MockAssetTokenDao();

  @override
  ProvenanceDao get provenanceDao => MockProvenanceDao();

  @override
  TokenDao get tokenDao => MockTokenDao();
}
