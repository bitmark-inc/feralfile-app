import 'package:autonomy_flutter/gateway/airdrop_api.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/airdrop_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
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
import '../mock_data/airdrop_mock.dart';

void main() async {
  late AirdropApi airdropApi;
  late AssetTokenDao assetTokenDao;
  late AccountService accountService;
  late TezosService tezosService;
  late TokensService tokensService;
  late FeralFileService feralFileService;
  late IndexerService indexerService;
  late NavigationService navigationService;

  late AirdropService airdropService;

  setUp(() {
    airdropApi = MockAirdropApi();
    assetTokenDao = MockAssetTokenDao();
    accountService = MockAccountService();
    tezosService = MockTezosService();
    tokensService = MockTokensService();
    feralFileService = MockFeralFileService();
    indexerService = MockIndexerService();
    navigationService = MockNavigationService();

    airdropService = AirdropService(
      airdropApi,
      assetTokenDao,
      accountService,
      tezosService,
      tokensService,
      feralFileService,
      indexerService,
      navigationService,
    );
    AirdropApiMock.setup(airdropApi);
  });

  group('share api', () {
    test('share valid', () async {
      final req = AirdropApiMock.shareValid.req;
      expect(
          await airdropService.share(req.last), AirdropApiMock.shareValid.res);

      verify(airdropApi.share(req.first, req.last)).called(1);
    });

    test('share 400', () async {
      final req = AirdropApiMock.shareDioException4xx.req;
      final error = airdropService.share(req.last);
      expect(error, throwsA(AirdropApiMock.shareDioException4xx.res));
      verify(airdropApi.share(req.first, req.last)).called(1);
    });

    test('share 500', () async {
      final req = AirdropApiMock.shareDioException5xx.req;
      final error = airdropService.share(req.last);
      expect(error, throwsA(AirdropApiMock.shareDioException5xx.res));
      verify(airdropApi.share(req.first, req.last)).called(1);
    });

    test('share connection timeout', () async {
      final req = AirdropApiMock.shareConnectionTimeout.req;
      final error = airdropService.share(req.last);
      expect(error, throwsA(AirdropApiMock.shareConnectionTimeout.res));
      verify(airdropApi.share(req.first, req.last)).called(1);
    });

    test('share receive timeout', () async {
      final req = AirdropApiMock.shareReceiveTimeout.req;
      final error = airdropService.share(req.last);
      expect(error, throwsA(AirdropApiMock.shareReceiveTimeout.res));
      verify(airdropApi.share(req.first, req.last)).called(1);
    });

    test('share exception other', () async {
      final req = AirdropApiMock.shareExceptionOther.req;
      final error = airdropService.share(req.last);
      expect(error, throwsA(AirdropApiMock.shareExceptionOther.res));
      verify(airdropApi.share(req.first, req.last)).called(1);
    });
  });

  group('claimShare api', () {
    test('claimShare valid', () async {
      final req = AirdropClaimShareRequest(
        shareCode: AirdropApiMock.claimShareValid.req,
      );
      expect(await airdropService.claimShare(req),
          AirdropApiMock.claimShareValid.res);

      verify(airdropApi.claimShare(req.shareCode)).called(1);
    });

    test('claimShare 400', () async {
      final req = AirdropClaimShareRequest(
        shareCode: AirdropApiMock.claimShareDioException4xx.req,
      );
      final error = airdropService.claimShare(req);
      expect(error, throwsA(AirdropApiMock.claimShareDioException4xx.res));
      verify(airdropApi.claimShare(req.shareCode)).called(1);
    });

    test('claimShare 500', () async {
      final req = AirdropClaimShareRequest(
        shareCode: AirdropApiMock.claimShareDioException5xx.req,
      );
      final error = airdropService.claimShare(req);
      expect(error, throwsA(AirdropApiMock.claimShareDioException5xx.res));
      verify(airdropApi.claimShare(req.shareCode)).called(1);
    });

    test('claimShare connection timeout', () async {
      final req = AirdropClaimShareRequest(
        shareCode: AirdropApiMock.claimShareConnectionTimeout.req,
      );
      final error = airdropService.claimShare(req);
      expect(error, throwsA(AirdropApiMock.claimShareConnectionTimeout.res));
      verify(airdropApi.claimShare(req.shareCode)).called(1);
    });

    test('claimShare receive timeout', () async {
      final req = AirdropClaimShareRequest(
        shareCode: AirdropApiMock.claimShareReceiveTimeout.req,
      );
      final error = airdropService.claimShare(req);
      expect(error, throwsA(AirdropApiMock.claimShareReceiveTimeout.res));
      verify(airdropApi.claimShare(req.shareCode)).called(1);
    });

    test('claimShare exception other', () async {
      final req = AirdropClaimShareRequest(
        shareCode: AirdropApiMock.claimShareExceptionOther.req,
      );
      final error = airdropService.claimShare(req);
      expect(error, throwsA(AirdropApiMock.claimShareExceptionOther.res));
      verify(airdropApi.claimShare(req.shareCode)).called(1);
    });
  });

  group('requestClaim api', () {
    test('requestClaim valid', () async {
      final req = AirdropApiMock.requestClaimValid.req;
      expect(await airdropService.requestClaim(req),
          AirdropApiMock.requestClaimValid.res);

      verify(airdropApi.requestClaim(req)).called(1);
    });

    test('requestClaim 400', () async {
      final req = AirdropApiMock.requestClaimDioException4xx.req;
      final error = airdropService.requestClaim(req);
      expect(error, throwsA(AirdropApiMock.requestClaimDioException4xx.res));
      verify(airdropApi.requestClaim(req)).called(1);
    });

    test('requestClaim 500', () async {
      final req = AirdropApiMock.requestClaimDioException5xx.req;
      final error = airdropService.requestClaim(req);
      expect(error, throwsA(AirdropApiMock.requestClaimDioException5xx.res));
      verify(airdropApi.requestClaim(req)).called(1);
    });

    test('requestClaim connection timeout', () async {
      final req = AirdropApiMock.requestClaimConnectionTimeout.req;
      final error = airdropService.requestClaim(req);
      expect(error, throwsA(AirdropApiMock.requestClaimConnectionTimeout.res));
      verify(airdropApi.requestClaim(req)).called(1);
    });

    test('requestClaim receive timeout', () async {
      final req = AirdropApiMock.requestClaimReceiveTimeout.req;
      final error = airdropService.requestClaim(req);
      expect(error, throwsA(AirdropApiMock.requestClaimReceiveTimeout.res));
      verify(airdropApi.requestClaim(req)).called(1);
    });

    test('requestClaim exception other', () async {
      final req = AirdropApiMock.requestClaimExceptionOther.req;
      final error = airdropService.requestClaim(req);
      expect(error, throwsA(AirdropApiMock.requestClaimExceptionOther.res));
      verify(airdropApi.requestClaim(req)).called(1);
    });
  });
}
