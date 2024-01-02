import 'package:autonomy_flutter/gateway/airdrop_api.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/service/airdrop_service.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';

import 'api_mock_data.dart';
import 'constants.dart';

class AirdropApiMock {
  //// requestClaim
  static final MockData requestClaimValid = MockData(
    req: AirdropRequestClaimRequest(
      ownerAddress: ownerAddress,
      id: id,
      indexID: indexID,
    ),
    res: AirdropRequestClaimResponse(claimID: claimID, seriesID: seriesID),
  );

  static final MockData requestClaimDioException4xx = MockData(
    req: AirdropRequestClaimRequest(
      ownerAddress: ownerAddress,
      id: idDioException4xx,
      indexID: indexID,
    ),
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 400,
        data: {'message': 'invalid id'},
      ),
    ),
  );

  static final MockData requestClaimDioException5xx = MockData(
    req: AirdropRequestClaimRequest(
      ownerAddress: ownerAddress,
      id: idDioException5xx,
      indexID: indexID,
    ),
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 500,
        data: {'message': 'internal server error'},
      ),
    ),
  );

  static final MockData requestClaimConnectionTimeout = MockData(
    req: AirdropRequestClaimRequest(
      ownerAddress: ownerAddress,
      id: idConnectionTimeout,
      indexID: indexID,
    ),
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.connectionTimeout,
      error: 'requestClaimConnectionTimeout',
    ),
  );

  static final MockData requestClaimReceiveTimeout = MockData(
    req: AirdropRequestClaimRequest(
      ownerAddress: ownerAddress,
      id: idReceiveTimeout,
      indexID: indexID,
    ),
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.receiveTimeout,
      error: 'requestClaimReceiveTimeout',
    ),
  );

  static final MockData requestClaimExceptionOther = MockData(
    req: AirdropRequestClaimRequest(
      ownerAddress: ownerAddress,
      id: idExceptionOther,
      indexID: indexID,
    ),
    res: Exception('requestClaimExceptionOther'),
  );

  //// claim
  static final MockData claimValid = MockData(
    req: AirdropClaimRequest(
      claimId: claimID,
      shareCode: shareCode,
      receivingAddress: receivingAddress,
      did: did,
      didSignature: didSignature,
      timestamp: timestamp,
    ),
    res: TokenClaimResponse(TokenClaimResult(
      id,
      claimerID,
      exhibitionID,
      artworkID,
      txID,
      seriesID,
      metadata,
    )),
  );

  static final MockData claimDioException4xx = MockData(
    req: AirdropClaimRequest(
      claimId: claimIDDioException4xx,
      shareCode: shareCode,
      receivingAddress: receivingAddress,
      did: did,
      didSignature: didSignature,
      timestamp: timestamp,
    ),
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 400,
        data: {'message': 'invalid id'},
      ),
    ),
  );

  static final MockData claimDioException5xx = MockData(
    req: AirdropClaimRequest(
      claimId: claimIDDioException5xx,
      shareCode: shareCode,
      receivingAddress: receivingAddress,
      did: did,
      didSignature: didSignature,
      timestamp: timestamp,
    ),
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 500,
        data: {'message': 'internal server error'},
      ),
    ),
  );

  static final MockData claimConnectionTimeout = MockData(
    req: AirdropClaimRequest(
      claimId: claimIDConnectionTimeout,
      shareCode: shareCode,
      receivingAddress: receivingAddress,
      did: did,
      didSignature: didSignature,
      timestamp: timestamp,
    ),
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.connectionTimeout,
      error: 'claimConnectionTimeout',
    ),
  );

  static final MockData claimReceiveTimeout = MockData(
    req: AirdropClaimRequest(
      claimId: claimIDReceiveTimeout,
      shareCode: shareCode,
      receivingAddress: receivingAddress,
      did: did,
      didSignature: didSignature,
      timestamp: timestamp,
    ),
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.receiveTimeout,
      error: 'claimReceiveTimeout',
    ),
  );

  static final MockData claimExceptionOther = MockData(
    req: AirdropClaimRequest(
      claimId: claimIDExceptionOther,
      shareCode: shareCode,
      receivingAddress: receivingAddress,
      did: did,
      didSignature: didSignature,
      timestamp: timestamp,
    ),
    res: Exception('claimExceptionOther'),
  );

  //// claimShare
  static final MockData claimShareValid = MockData(
    req: shareCode,
    res: AirdropClaimShareResponse(shareCode: shareCode, seriesID: seriesID),
  );

  static final MockData claimShareDioException4xx = MockData(
    req: shareCodeDioException4xx,
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 400,
        data: {'message': 'invalid id'},
      ),
    ),
  );

  static final MockData claimShareDioException5xx = MockData(
    req: shareCodeDioException5xx,
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 500,
        data: {'message': 'internal server error'},
      ),
    ),
  );

  static final MockData claimShareConnectionTimeout = MockData(
    req: shareCodeConnectionTimeout,
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.connectionTimeout,
      error: 'claimShareConnectionTimeout',
    ),
  );

  static final MockData claimShareReceiveTimeout = MockData(
    req: shareCodeReceiveTimeout,
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.receiveTimeout,
      error: 'claimShareReceiveTimeout',
    ),
  );

  static final MockData claimShareExceptionOther = MockData(
    req: shareCodeExceptionOther,
    res: Exception('claimShareExceptionOther'),
  );

  //// share
  static final MockData shareValid =
      MockData<List<dynamic>, AirdropShareResponse>(
    req: [
      tokenID,
      AirdropShareRequest(
        tokenId: tokenID,
        ownerAddress: ownerAddress,
        ownerPublicKey: ownerPublicKey,
        timestamp: timestamp,
        signature: signature,
      )
    ],
    res: AirdropShareResponse(deepLink: deepLink),
  );

  static final MockData shareDioException4xx = MockData(
    req: [
      tokenIDDioException4xx,
      AirdropShareRequest(
        tokenId: tokenIDDioException4xx,
        ownerAddress: ownerAddress,
        ownerPublicKey: ownerPublicKey,
        timestamp: timestamp,
        signature: signature,
      )
    ],
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 400,
        data: {'message': 'invalid id'},
      ),
    ),
  );

  static final MockData shareDioException5xx = MockData(
    req: [
      tokenIDDioException5xx,
      AirdropShareRequest(
        tokenId: tokenIDDioException5xx,
        ownerAddress: ownerAddress,
        ownerPublicKey: ownerPublicKey,
        timestamp: timestamp,
        signature: signature,
      )
    ],
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 500,
        data: {'message': 'internal server error'},
      ),
    ),
  );

  static final MockData shareConnectionTimeout = MockData(
    req: [
      tokenIDConnectionTimeout,
      AirdropShareRequest(
        tokenId: tokenIDConnectionTimeout,
        ownerAddress: ownerAddress,
        ownerPublicKey: ownerPublicKey,
        timestamp: timestamp,
        signature: signature,
      )
    ],
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.connectionTimeout,
      error: 'shareConnectionTimeout',
    ),
  );

  static final MockData shareReceiveTimeout = MockData(
    req: [
      tokenIDReceiveTimeout,
      AirdropShareRequest(
        tokenId: tokenIDReceiveTimeout,
        ownerAddress: ownerAddress,
        ownerPublicKey: ownerPublicKey,
        timestamp: timestamp,
        signature: signature,
      )
    ],
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.receiveTimeout,
      error: 'shareReceiveTimeout',
    ),
  );

  static final MockData shareExceptionOther = MockData(
    req: [
      tokenIDExceptionOther,
      AirdropShareRequest(
        tokenId: tokenIDExceptionOther,
        ownerAddress: ownerAddress,
        ownerPublicKey: ownerPublicKey,
        timestamp: timestamp,
        signature: signature,
      )
    ],
    res: Exception('shareExceptionOther'),
  );

  static Future<void> setup(AirdropApi mockAirdropApi) async {
    when(mockAirdropApi.share(AirdropApiMock.shareValid.req.first,
            AirdropApiMock.shareValid.req.last))
        .thenAnswer((_) async => AirdropApiMock.shareValid.res);
    when(mockAirdropApi.share(AirdropApiMock.shareDioException4xx.req.first,
            AirdropApiMock.shareDioException4xx.req.last))
        .thenThrow(AirdropApiMock.shareDioException4xx.res);
    when(mockAirdropApi.share(AirdropApiMock.shareDioException5xx.req.first,
            AirdropApiMock.shareDioException5xx.req.last))
        .thenThrow(AirdropApiMock.shareDioException5xx.res);
    when(mockAirdropApi.share(AirdropApiMock.shareConnectionTimeout.req.first,
            AirdropApiMock.shareConnectionTimeout.req.last))
        .thenThrow(AirdropApiMock.shareConnectionTimeout.res);
    when(mockAirdropApi.share(AirdropApiMock.shareReceiveTimeout.req.first,
            AirdropApiMock.shareReceiveTimeout.req.last))
        .thenThrow(AirdropApiMock.shareReceiveTimeout.res);
    when(mockAirdropApi.share(AirdropApiMock.shareExceptionOther.req.first,
            AirdropApiMock.shareExceptionOther.req.last))
        .thenThrow(AirdropApiMock.shareExceptionOther.res);

    // claimShare
    when(mockAirdropApi.claimShare(AirdropApiMock.claimShareValid.req))
        .thenAnswer((_) async => AirdropApiMock.claimShareValid.res);
    when(mockAirdropApi
            .claimShare(AirdropApiMock.claimShareDioException4xx.req))
        .thenThrow(AirdropApiMock.claimShareDioException4xx.res);
    when(mockAirdropApi
            .claimShare(AirdropApiMock.claimShareDioException5xx.req))
        .thenThrow(AirdropApiMock.claimShareDioException5xx.res);
    when(mockAirdropApi
            .claimShare(AirdropApiMock.claimShareConnectionTimeout.req))
        .thenThrow(AirdropApiMock.claimShareConnectionTimeout.res);
    when(mockAirdropApi.claimShare(AirdropApiMock.claimShareReceiveTimeout.req))
        .thenThrow(AirdropApiMock.claimShareReceiveTimeout.res);
    when(mockAirdropApi.claimShare(AirdropApiMock.claimShareExceptionOther.req))
        .thenThrow(AirdropApiMock.claimShareExceptionOther.res);

    //requestClaim
    when(mockAirdropApi.requestClaim(AirdropApiMock.requestClaimValid.req))
        .thenAnswer((_) async => AirdropApiMock.requestClaimValid.res);
    when(mockAirdropApi
            .requestClaim(AirdropApiMock.requestClaimDioException4xx.req))
        .thenThrow(AirdropApiMock.requestClaimDioException4xx.res);
    when(mockAirdropApi
            .requestClaim(AirdropApiMock.requestClaimDioException5xx.req))
        .thenThrow(AirdropApiMock.requestClaimDioException5xx.res);
    when(mockAirdropApi
            .requestClaim(AirdropApiMock.requestClaimConnectionTimeout.req))
        .thenThrow(AirdropApiMock.requestClaimConnectionTimeout.res);
    when(mockAirdropApi
            .requestClaim(AirdropApiMock.requestClaimReceiveTimeout.req))
        .thenThrow(AirdropApiMock.requestClaimReceiveTimeout.res);
    when(mockAirdropApi
            .requestClaim(AirdropApiMock.requestClaimExceptionOther.req))
        .thenThrow(AirdropApiMock.requestClaimExceptionOther.res);

    //claim
    when(mockAirdropApi.claim(AirdropApiMock.claimValid.req))
        .thenAnswer((_) async => AirdropApiMock.claimValid.res);
    when(mockAirdropApi.claim(AirdropApiMock.claimDioException4xx.req))
        .thenThrow(AirdropApiMock.claimDioException4xx.res);
    when(mockAirdropApi.claim(AirdropApiMock.claimDioException5xx.req))
        .thenThrow(AirdropApiMock.claimDioException5xx.res);
    when(mockAirdropApi.claim(AirdropApiMock.claimConnectionTimeout.req))
        .thenThrow(AirdropApiMock.claimConnectionTimeout.res);
    when(mockAirdropApi.claim(AirdropApiMock.claimReceiveTimeout.req))
        .thenThrow(AirdropApiMock.claimReceiveTimeout.res);
    when(mockAirdropApi.claim(AirdropApiMock.claimExceptionOther.req))
        .thenThrow(AirdropApiMock.claimExceptionOther.res);
  }
}
