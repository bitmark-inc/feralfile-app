import 'package:autonomy_flutter/nft_collection/database/nft_collection_database.dart';
import 'package:autonomy_flutter/nft_collection/nft_collection.dart';
import 'package:autonomy_flutter/nft_collection/services/address_service.dart';
import 'package:autonomy_flutter/nft_collection/services/configuration_service.dart';
import 'package:autonomy_flutter/nft_collection/services/tokens_service.dart';
import 'package:autonomy_flutter/widgetbook/mock/nft_collection/mock_nft_address_service.dart';
import 'package:autonomy_flutter/widgetbook/mock/nft_collection/mock_nft_collection_database.dart';
import 'package:autonomy_flutter/widgetbook/mock/nft_collection/mock_token_service.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockNftCollection {
  static Logger logger = Logger('nft_collection');
  static Logger apiLog = Logger('nft_collection_api_log');
  static late NftTokensService tokenService;
  static late NftCollectionPrefs prefs;
  static late NftCollectionDatabase database;
  static late NftAddressService addressService;

  static Future<void> initNftCollection() async {
    if (logger != null) {
      NftCollection.logger = logger;
    }
    database = MockNftCollectionDatabase();
    tokenService = MockTokensService();

    final sharedPreferences = await SharedPreferences.getInstance();

    prefs = NftCollectionPrefs(sharedPreferences);
    addressService = MockNftAddressService();
  }
}
