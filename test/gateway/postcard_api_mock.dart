// ignore_for_file: discarded_futures

import 'package:autonomy_flutter/gateway/postcard_api.dart';
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_page.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';

import 'api_mock_data.dart';
import 'constants.dart';

typedef ReceivePostcardRequest = Map<String, dynamic>;

class PostcardApiMock {
  static void setup(PostcardApi postcardApi) {
    _setupClaimEmptyApi(postcardApi);
    _setupReceiveApi(postcardApi);
  }

  static void _setupClaimEmptyApi(PostcardApi postcardApi) {
    final claimValid = PostcardApiMock.claimValid;
    when(postcardApi.claim(claimValid.req))
        .thenAnswer((_) async => claimValid.res);

    final claimException4xx = PostcardApiMock.claimException4xx;
    when(postcardApi.claim(claimException4xx.req))
        .thenThrow(claimException4xx.res);

    final claimException5xx = PostcardApiMock.claimException5xx;
    when(postcardApi.claim(claimException5xx.req))
        .thenThrow(claimException5xx.res);

    final claimConnectionTimeout = PostcardApiMock.claimConnectionTimeout;
    when(postcardApi.claim(claimConnectionTimeout.req))
        .thenThrow(claimConnectionTimeout.res);

    final claimReceiveTimeout = PostcardApiMock.claimReceiveTimeout;
    when(postcardApi.claim(claimReceiveTimeout.req))
        .thenThrow(claimReceiveTimeout.res);

    final claimDioExceptionOther = PostcardApiMock.claimDioExceptionOther;
    when(postcardApi.claim(claimDioExceptionOther.req))
        .thenThrow(claimDioExceptionOther.res);
  }

  static final MockData<ClaimPostCardRequest, ClaimPostCardResponse>
      claimValid = MockData(
    req: ClaimPostCardRequest(
      location: listLocation,
      address: address,
      signature: signature,
      timestamp: timestamp,
      publicKey: publicKey,
    ),
    res: ClaimPostCardResponse(
      tokenID: tokenID,
      imageCID: imageCID,
      blockchain: blockchain,
      owner: owner,
      contractAddress: contractAddress,
    ),
  );
  static final MockData<ClaimPostCardRequest, DioException> claimException4xx =
      MockData(
    req: ClaimPostCardRequest(
      location: listLocation,
      claimID: claimIDDioException4xx,
    ),
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 400,
        data: {
          'message': 'invalid id',
        },
      ),
    ),
  );
  static final MockData<ClaimPostCardRequest, DioException> claimException5xx =
      MockData(
    req: ClaimPostCardRequest(
      location: listLocation,
      claimID: claimIDDioException5xx,
    ),
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 500,
        data: {
          'message': 'internal server error',
        },
      ),
    ),
  );
  static final MockData<ClaimPostCardRequest, DioException>
      claimConnectionTimeout = MockData(
    req: ClaimPostCardRequest(
      location: listLocation,
      claimID: claimIDConnectionTimeout,
    ),
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.connectionTimeout,
      error: 'claimConnectionTimeout',
    ),
  );
  static final MockData<ClaimPostCardRequest, DioException>
      claimReceiveTimeout = MockData(
    req: ClaimPostCardRequest(
      location: listLocation,
      claimID: claimIDReceiveTimeout,
    ),
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.receiveTimeout,
      error: 'claimReceiveTimeout',
    ),
  );
  static final MockData<ClaimPostCardRequest, Exception>
      claimDioExceptionOther = MockData(
    req: ClaimPostCardRequest(
      location: listLocation,
      claimID: claimIDExceptionOther,
    ),
    res: Exception('claimExceptionOther'),
  );
  static final MockData<ClaimPostCardRequest, DioException> claimLimit =
      MockData(
    req: ClaimPostCardRequest(
      location: listLocation,
      claimID: claimIDLimit,
    ),
    res: DioException(
        requestOptions: RequestOptions(path: 'path'),
        response: Response(
            requestOptions: RequestOptions(path: 'path'),
            statusCode: 429,
            data: {'message': 'claim limit'})),
  );

  static void _setupReceiveApi(PostcardApi postcardApi) {
    final receiveValid = PostcardApiMock.receiveValid;
    when(postcardApi.receive(receiveValid.req))
        .thenAnswer((_) async => receiveValid.res);

    final receiveException4xx = PostcardApiMock.receiveException4xx;
    when(postcardApi.receive(receiveException4xx.req))
        .thenThrow(receiveException4xx.res);

    final receiveException5xx = PostcardApiMock.receiveException5xx;
    when(postcardApi.receive(receiveException5xx.req))
        .thenThrow(receiveException5xx.res);

    final receiveConnectionTimeout = PostcardApiMock.receiveConnectionTimeout;
    when(postcardApi.receive(receiveConnectionTimeout.req))
        .thenThrow(receiveConnectionTimeout.res);

    final receiveReceiveTimeout = PostcardApiMock.receiveReceiveTimeout;
    when(postcardApi.receive(receiveReceiveTimeout.req))
        .thenThrow(receiveReceiveTimeout.res);

    final receiveDioExceptionOther = PostcardApiMock.receiveDioExceptionOther;
    when(postcardApi.receive(receiveDioExceptionOther.req))
        .thenThrow(receiveDioExceptionOther.res);
  }

  static final MockData<ReceivePostcardRequest, ReceivePostcardResponse>
      receiveValid = MockData(
    req: {
      'shareCode': shareCode,
      'location': location,
      'address': address,
      'signature': signature,
      'timestamp': timestamp,
      'publicKey': publicKey,
    },
    res: ReceivePostcardResponse(
      tokenID,
      imageCID,
      blockchain,
      owner,
      contractAddress,
    ),
  );
  static final MockData<ReceivePostcardRequest, DioException>
      receiveException4xx = MockData(
    req: {
      'shareCode': shareCodeDioException4xx,
      'location': location,
      'address': address,
      'signature': signature,
      'timestamp': timestamp,
      'publicKey': publicKey,
    },
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 400,
        data: {
          'message': 'invalid id',
        },
      ),
    ),
  );
  static final MockData<ReceivePostcardRequest, DioException>
      receiveException5xx = MockData(
    req: {
      'shareCode': shareCodeDioException5xx,
      'location': location,
      'address': address,
      'signature': signature,
      'timestamp': timestamp,
      'publicKey': publicKey,
    },
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      response: Response(
        requestOptions: RequestOptions(path: 'path'),
        statusCode: 500,
        data: {
          'message': 'internal server error',
        },
      ),
    ),
  );
  static final MockData<ReceivePostcardRequest, DioException>
      receiveConnectionTimeout = MockData(
    req: {
      'shareCode': shareCodeConnectionTimeout,
      'location': location,
      'address': address,
      'signature': signature,
      'timestamp': timestamp,
      'publicKey': publicKey,
    },
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.connectionTimeout,
      error: 'receiveConnectionTimeout',
    ),
  );
  static final MockData<ReceivePostcardRequest, DioException>
      receiveReceiveTimeout = MockData(
    req: {
      'shareCode': shareCodeReceiveTimeout,
      'location': location,
      'address': address,
      'signature': signature,
      'timestamp': timestamp,
      'publicKey': publicKey,
    },
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      type: DioExceptionType.receiveTimeout,
      error: 'receiveReceiveTimeout',
    ),
  );
  static final MockData<ReceivePostcardRequest, DioException>
      receiveDioExceptionOther = MockData(
    req: {
      'shareCode': shareCodeExceptionOther,
      'location': location,
      'address': address,
      'signature': signature,
      'timestamp': timestamp,
      'publicKey': publicKey
    },
    res: DioException(
      requestOptions: RequestOptions(path: 'path'),
      error: 'receiveDioExceptionOther',
    ),
  );
}
