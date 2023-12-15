// ignore_for_file: discarded_futures

import 'package:mockito/mockito.dart';
import 'package:nft_collection/models/asset_token.dart';

import '../services/activation_service_test.mocks.dart';
import 'constants.dart';

class TokenServiceMockData {
  static AssetToken anyAssetToken = AssetToken(
      id: id,
      edition: 0,
      editionName: 'editionName',
      blockchain: blockchain,
      fungible: true,
      contractType: 'contractType',
      tokenId: tokenID,
      contractAddress: contractAddress,
      owner: '',
      owners: {},
      lastActivityTime: DateTime.now(),
      lastRefreshedTime: DateTime.now(),
      provenance: [],
      originTokenInfo: null,
      balance: null);

  static void setUp(MockTokensService tokensService) {
    when(tokensService.setCustomTokens(any))
        .thenAnswer((_) => Future.value()); // ignore: always_specify_types
  }
}
