//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/util/dio_exception_ext.dart';
import 'package:autonomy_flutter/util/dio_interceptors.dart';
import 'package:autonomy_flutter/util/isolated_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Dio feralFileDio(BaseOptions options) {
  final dio = baseDio(options);
  dio.interceptors.add(FeralfileAuthInterceptor());
  return dio;
}

Dio customerSupportDio(BaseOptions options) {
  final dio = baseDio(options);
  dio.interceptors.add(CustomerSupportInterceptor());
  return dio;
}

Dio postcardDio(BaseOptions options) {
  final dio = baseDio(options);
  dio.interceptors.add(HmacAuthInterceptor(Environment.auClaimSecretKey));
  dio.interceptors.add(AutonomyAuthInterceptor());
  return dio;
}

Dio tvCastDio(BaseOptions options) {
  final dio = Dio(options);
  dio.interceptors.add(LoggingInterceptor());
  dio.interceptors.add(ConnectingExceptionInterceptor());
  dio.interceptors.add(TVKeyInterceptor(Environment.tvKey));
  // capture 4xx and 5xx errors
  dio.addSentry(failedRequestStatusCodes: [SentryStatusCode.range(400, 599)]);
  return dio;
}

Dio chatDio(BaseOptions options) {
  final dio = baseDio(options);
  dio.interceptors.add(HmacAuthInterceptor(Environment.chatServerHmacKey));
  return dio;
}

Dio baseDio(BaseOptions options) {
  final BaseOptions dioOptions = options.copyWith(
    followRedirects: true,
    connectTimeout: options.connectTimeout ?? const Duration(seconds: 10),
    receiveTimeout: options.receiveTimeout ?? const Duration(seconds: 10),
  );
  final dio = Dio(); // Default a dio instance
  dio.interceptors.add(RetryInterceptor(
    dio: dio,
    logPrint: (message) {
      log.warning('[request retry] $message');
    },
    retryEvaluator: (error, attempt) {
      if (error.statusCode == 404) {
        return false;
      }
      return true;
    },
    ignoreRetryEvaluatorExceptions: true,
    retryDelays: const [
      // set delays between retries
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ],
  ));

  dio.interceptors.add(LoggingInterceptor());
  dio.interceptors.add(ConnectingExceptionInterceptor());
  (dio.transformer as SyncTransformer).jsonDecodeCallback = parseJson;
  dio
    ..options = dioOptions

    // Temporarily comment out due to an error of fetching in the background
    // Error: ClientException: Exception building CronetEngine: Bad state:
    // The BackgroundIsolateBinaryMessenger.instance value is invalid until
    // BackgroundIsolateBinaryMessenger.ensureInitialized is executed.
    //
    // if (Platform.isIOS || Platform.isMacOS || Platform.isAndroid) {
    //   dio.httpClientAdapter = NativeAdapter();
    // }
    ..addSentry(failedRequestStatusCodes: [SentryStatusCode.range(500, 599)]);

  return dio;
}

Future<void> parseJson(String text) => IsolatedUtil().parseAndDecode(text);
