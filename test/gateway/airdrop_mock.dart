import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/service/airdrop_service.dart';
import 'package:dio/dio.dart';

import 'api_mock_data.dart';
import 'constants.dart';

class AirdropApiMock {
  //// requestClaim
  static final MockData requestClaimValid = MockData(
    AirdropRequestClaimRequest(
      ownerAddress: ownerAddress,
      id: id,
      indexID: indexID,
    ),
    AirdropRequestClaimResponse(claimID: claimID, seriesID: seriesID),
  );

  static final MockData requestClaimDioException4xx = MockData(
    AirdropRequestClaimRequest(
      ownerAddress: ownerAddress,
      id: idDioException4xx,
      indexID: indexID,
    ),
    DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 400,
        data: {'message': 'invalid id'},
      ),
    ),
  );

  static final MockData requestClaimDioException5xx = MockData(
    AirdropRequestClaimRequest(
      ownerAddress: ownerAddress,
      id: idDioException5xx,
      indexID: indexID,
    ),
    DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 500,
        data: {'message': 'internal server error'},
      ),
    ),
  );

  static final MockData requestClaimConnectionTimeout = MockData(
    AirdropRequestClaimRequest(
      ownerAddress: ownerAddress,
      id: idConnectionTimeout,
      indexID: indexID,
    ),
    DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.connectionTimeout,
      error: 'requestClaimConnectionTimeout',
    ),
  );

  static final MockData requestClaimReceiveTimeout = MockData(
    AirdropRequestClaimRequest(
      ownerAddress: ownerAddress,
      id: idReceiveTimeout,
      indexID: indexID,
    ),
    DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.receiveTimeout,
      error: 'requestClaimReceiveTimeout',
    ),
  );

  static final MockData requestClaimExceptionOther = MockData(
    AirdropRequestClaimRequest(
      ownerAddress: ownerAddress,
      id: idExceptionOther,
      indexID: indexID,
    ),
    Exception('requestClaimExceptionOther'),
  );

  //// claim
  static final MockData claimValid = MockData(
    AirdropClaimRequest(
      claimId: claimID,
      shareCode: shareCode,
      receivingAddress: receivingAddress,
      did: did,
      didSignature: didSignature,
      timestamp: timestamp,
    ),
    TokenClaimResponse(TokenClaimResult(
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
    AirdropClaimRequest(
      claimId: claimIDDioException4xx,
      shareCode: shareCode,
      receivingAddress: receivingAddress,
      did: did,
      didSignature: didSignature,
      timestamp: timestamp,
    ),
    DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 400,
        data: {'message': 'invalid id'},
      ),
    ),
  );

  static final MockData claimDioException5xx = MockData(
    AirdropClaimRequest(
      claimId: claimIDDioException5xx,
      shareCode: shareCode,
      receivingAddress: receivingAddress,
      did: did,
      didSignature: didSignature,
      timestamp: timestamp,
    ),
    DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 500,
        data: {'message': 'internal server error'},
      ),
    ),
  );

  static final MockData claimConnectionTimeout = MockData(
    AirdropClaimRequest(
      claimId: claimIDConnectionTimeout,
      shareCode: shareCode,
      receivingAddress: receivingAddress,
      did: did,
      didSignature: didSignature,
      timestamp: timestamp,
    ),
    DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.connectionTimeout,
      error: 'claimConnectionTimeout',
    ),
  );

  static final MockData claimReceiveTimeout = MockData(
    AirdropClaimRequest(
      claimId: claimIDReceiveTimeout,
      shareCode: shareCode,
      receivingAddress: receivingAddress,
      did: did,
      didSignature: didSignature,
      timestamp: timestamp,
    ),
    DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.receiveTimeout,
      error: 'claimReceiveTimeout',
    ),
  );

  static final MockData claimExceptionOther = MockData(
    AirdropClaimRequest(
      claimId: claimIDExceptionOther,
      shareCode: shareCode,
      receivingAddress: receivingAddress,
      did: did,
      didSignature: didSignature,
      timestamp: timestamp,
    ),
    Exception('claimExceptionOther'),
  );

  //// claimShare
  static final MockData claimShareValid = MockData(
    shareCode,
    AirdropClaimShareResponse(shareCode: shareCode, seriesID: seriesID),
  );

  static final MockData claimShareDioException4xx = MockData(
    shareCodeDioException4xx,
    DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 400,
        data: {'message': 'invalid id'},
      ),
    ),
  );

  static final MockData claimShareDioException5xx = MockData(
    shareCodeDioException5xx,
    DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 500,
        data: {'message': 'internal server error'},
      ),
    ),
  );

  static final MockData claimShareConnectionTimeout = MockData(
    shareCodeConnectionTimeout,
    DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.connectionTimeout,
      error: 'claimShareConnectionTimeout',
    ),
  );

  static final MockData claimShareReceiveTimeout = MockData(
    shareCodeReceiveTimeout,
    DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.receiveTimeout,
      error: 'claimShareReceiveTimeout',
    ),
  );

  static final MockData claimShareExceptionOther = MockData(
    shareCodeExceptionOther,
    Exception('claimShareExceptionOther'),
  );

  //// share
  static final MockData shareValid = MockData(
    [
      tokenID,
      AirdropShareRequest(
        tokenId: tokenID,
        ownerAddress: ownerAddress,
        ownerPublicKey: ownerPublicKey,
        timestamp: timestamp,
        signature: signature,
      )
    ],
    AirdropShareResponse(deepLink: deepLink),
  );

  static final MockData shareDioException4xx = MockData(
    [
      tokenIDDioException4xx,
      AirdropShareRequest(
        tokenId: tokenIDDioException4xx,
        ownerAddress: ownerAddress,
        ownerPublicKey: ownerPublicKey,
        timestamp: timestamp,
        signature: signature,
      )
    ],
    DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 400,
        data: {'message': 'invalid id'},
      ),
    ),
  );

  static final MockData shareDioException5xx = MockData(
    [
      tokenIDDioException5xx,
      AirdropShareRequest(
        tokenId: tokenIDDioException5xx,
        ownerAddress: ownerAddress,
        ownerPublicKey: ownerPublicKey,
        timestamp: timestamp,
        signature: signature,
      )
    ],
    DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 500,
        data: {'message': 'internal server error'},
      ),
    ),
  );

  static final MockData shareConnectionTimeout = MockData(
    [
      tokenIDConnectionTimeout,
      AirdropShareRequest(
        tokenId: tokenIDConnectionTimeout,
        ownerAddress: ownerAddress,
        ownerPublicKey: ownerPublicKey,
        timestamp: timestamp,
        signature: signature,
      )
    ],
    DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.connectionTimeout,
      error: 'shareConnectionTimeout',
    ),
  );

  static final MockData shareReceiveTimeout = MockData(
    [
      tokenIDReceiveTimeout,
      AirdropShareRequest(
        tokenId: tokenIDReceiveTimeout,
        ownerAddress: ownerAddress,
        ownerPublicKey: ownerPublicKey,
        timestamp: timestamp,
        signature: signature,
      )
    ],
    DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.receiveTimeout,
      error: 'shareReceiveTimeout',
    ),
  );

  static final MockData shareExceptionOther = MockData(
    [
      tokenIDExceptionOther,
      AirdropShareRequest(
        tokenId: tokenIDExceptionOther,
        ownerAddress: ownerAddress,
        ownerPublicKey: ownerPublicKey,
        timestamp: timestamp,
        signature: signature,
      )
    ],
    Exception('shareExceptionOther'),
  );
}
