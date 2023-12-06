import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/service/airdrop_service.dart';
import 'package:dio/dio.dart';

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
  static final MockData shareValid = MockData(
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
}
