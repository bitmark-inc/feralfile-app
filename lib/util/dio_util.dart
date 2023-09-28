//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/environment.dart';
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

Dio postcardDio(BaseOptions options) {
  final dio = baseDio(options);
  dio.interceptors.add(HmacAuthInterceptor(Environment.auClaimSecretKey));
  return dio;
}

Dio airdropDio(BaseOptions options) {
  final dio = baseDio(options);
  dio.interceptors.add(AutonomyAuthInterceptor());
  dio.interceptors.add(HmacAuthInterceptor(Environment.auClaimSecretKey));
  dio.interceptors.add(AirdropInterceptor());
  return dio;
}

Dio feedDio(BaseOptions options) {
  final dio = baseDio(options);
  dio.interceptors.add(AutonomyAuthInterceptor());
  dio.interceptors.add(HmacAuthInterceptor(Environment.auClaimSecretKey));
  dio.interceptors.add(AirdropInterceptor());
  return dio;
}

Dio baseDio(BaseOptions options) {
  final BaseOptions dioOptions = BaseOptions(
    followRedirects: true,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );
  final dio = Dio(); // Default a dio instance
  dio.interceptors.add(RetryInterceptor(
    dio: dio,
    logPrint: (message) {
      log.warning("[request retry] $message");
    },
    retryDelays: const [
      // set delays between retries
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ],
  ));

  dio.interceptors.add(LoggingInterceptor());
  (dio.transformer as SyncTransformer).jsonDecodeCallback = parseJson;
  dio.options = dioOptions;

  // Temporarily comment out due to an error of fetching in the background
  // Error: ClientException: Exception building CronetEngine: Bad state:
  // The BackgroundIsolateBinaryMessenger.instance value is invalid until
  // BackgroundIsolateBinaryMessenger.ensureInitialized is executed.
  //
  // if (Platform.isIOS || Platform.isMacOS || Platform.isAndroid) {
  //   dio.httpClientAdapter = NativeAdapter();
  // }
  dio.addSentry(failedRequestStatusCodes: [SentryStatusCode.range(500, 599)]);

  return dio;
}

parseJson(String text) {
  return IsolatedUtil().parseAndDecode(text);
}
