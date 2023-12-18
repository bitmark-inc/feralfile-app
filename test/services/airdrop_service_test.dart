import 'package:autonomy_flutter/gateway/airdrop_api.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/airdrop_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nft_collection/database/dao/asset_token_dao.dart';
import 'package:nft_collection/services/indexer_service.dart';
import 'package:nft_collection/services/tokens_service.dart';

import '../generate_mock/dao/mock_asset_token_dao.mocks.dart';
import '../generate_mock/gateway/mock_airdrop_api.mocks.dart';
import '../generate_mock/service/mock_account_service.mocks.dart';
import '../generate_mock/service/mock_feral_file_service.mocks.dart';
import '../generate_mock/service/mock_indexer_service.mocks.dart';
import '../generate_mock/service/mock_navigation_service.mocks.dart';
import '../generate_mock/service/mock_tezos_service.mocks.dart';
import '../generate_mock/service/mock_tokens_service.mocks.dart';

void main() async {
  late AirdropApi _airdropApi;
  late AssetTokenDao _assetTokenDao;
  late AccountService _accountService;
  late TezosService _tezosService;
  late TokensService _tokensService;
  late FeralFileService _feralFileService;
  late IndexerService _indexerService;
  late NavigationService _navigationService;

  late AirdropService _airdropService;

  setUp(() {
    _airdropApi = MockAirdropApi();
    _assetTokenDao = MockAssetTokenDao();
    _accountService = MockAccountService();
    _tezosService = MockTezosService();
    _tokensService = MockTokensService();
    _feralFileService = MockFeralFileService();
    _indexerService = MockIndexerService();
    _navigationService = MockNavigationService();

    _airdropService = AirdropService(
      _airdropApi,
      _assetTokenDao,
      _accountService,
      _tezosService,
      _tokensService,
      _feralFileService,
      _indexerService,
      _navigationService,
    );
  });

  group('description', () {});
}
