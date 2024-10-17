//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/network_issue_manager.dart';
import 'package:autonomy_flutter/util/exception.dart';
import 'package:autonomy_flutter/util/exception_ext.dart';
import 'package:autonomy_flutter/util/isolated_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/crypto.dart';

class LoggingInterceptor extends Interceptor {
  LoggingInterceptor();

  static final List<String> _skipLogPaths = [
    Environment.pubdocURL,
    '${Environment.feralFileAPIURL}/api/exhibitions',
    '${Environment.feralFileAPIURL}/api/artworks',
  ];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final curl = cURLRepresentation(err.requestOptions);
    apiLog
      ..info('API Request: $curl')
      ..warning('Respond error: ${err.response}');
    return handler.next(err);
  }

  @override
  Future onResponse(
      Response response, ResponseInterceptorHandler handler) async {
    handler.next(response);
    await writeAPILog(response);
  }

  Future writeAPILog(Response response) async {
    final apiPath =
        response.requestOptions.baseUrl + response.requestOptions.path;
    final skipLog = _skipLogPaths.any((element) => apiPath.contains(element));
    if (skipLog) {
      return;
    }
    bool shortCurlLog = await IsolatedUtil().shouldShortCurlLog(apiPath);
    if (shortCurlLog) {
      final request = response.requestOptions;
      apiLog.fine(
          'API Request: ${request.method} ${request.uri} ${request.data}');
    } else {
      final curl = cURLRepresentation(response.requestOptions);
      apiLog.fine('API Request: $curl');
    }

    bool shortAPIResponseLog =
        await IsolatedUtil().shouldShortAPIResponseLog(apiPath);
    if (shortAPIResponseLog) {
      apiLog.info('API Response Status: ${response.statusCode}');
    } else {
      final message = response.toString();
      apiLog.fine('API Response: $message');
    }
  }

  String cURLRepresentation(RequestOptions options) {
    List<String> components = [r'$ curl -i'];
    if (options.method.toUpperCase() == 'GET') {
      components.add('-X ${options.method}');
    }

    options.headers.forEach((k, v) {
      if (k != 'Cookie') {
        components.add('-H "$k: $v"');
      }
    });

    try {
      var data = json.encode(options.data);
      data = data.replaceAll('"', r'\"');
      components.add('-d "$data"');
    } catch (err) {
      //ignore
    }

    components.add('"${options.uri}"');

    return components.join('\\\n\t');
  }
}

class SentryInterceptor extends InterceptorsWrapper {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    Map<String, dynamic> data = {
      'url': response.requestOptions.uri.toString(),
      'method': response.requestOptions.method,
      'status_code': response.statusCode,
    };
    unawaited(Sentry.addBreadcrumb(
      Breadcrumb(
        type: 'http',
        category: 'http',
        data: data,
      ),
    ));
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    unawaited(Sentry.addBreadcrumb(
      Breadcrumb(
        type: 'http',
        category: 'http',
        level: SentryLevel.error,
        data: {
          'url': err.requestOptions.uri.toString(),
          'method': err.requestOptions.method,
          'status_code': err.response?.statusCode ?? 'NA',
          'reason': err.type.name,
        },
        message: err.message,
      ),
    ));
    super.onError(err, handler);
  }
}

class AutonomyAuthInterceptor extends Interceptor {
  AutonomyAuthInterceptor();

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final shouldIgnoreAuthorizationPath = [
      IAPApi.addressAuthenticationPath,
      IAPApi.registerPrimaryAddressPath,
    ];
    if (!shouldIgnoreAuthorizationPath.contains(options.path)) {
      final jwt = await injector<AuthService>().getAuthToken();
      if (jwt == null) {
        unawaited(Sentry.captureMessage('JWT is null'));
        throw JwtException(
            message: 'JWT is null while request to ${options.path}');
      }
      options.headers['Authorization'] = 'Bearer ${jwt.jwtToken}';
    }

    return handler.next(options);
  }
}

class MetricsInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.headers['x-api-key'] == null) {
      options.headers['x-api-key'] = Environment.metricSecretKey;
    }
    handler.next(options);
  }
}

class QuickAuthInterceptor extends Interceptor {
  String jwtToken;

  QuickAuthInterceptor(this.jwtToken);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers['Authorization'] = 'Bearer $jwtToken';
    return handler.next(options);
  }
}

class FeralfileAuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.headers['X-Api-Signature'] == null &&
        options.method.toUpperCase() == 'POST') {
      final timestamp =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final canonicalString = List<String>.of([
        options.uri.toString(),
        json.encode(options.data),
        timestamp,
      ]).join('|');
      final hmacSha256 =
          Hmac(sha256, utf8.encode(Environment.feralFileSecretKey));
      final digest = hmacSha256.convert(utf8.encode(canonicalString));
      final sig = bytesToHex(digest.bytes);
      options.headers['X-Api-Signature'] = 't=$timestamp,s=$sig';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    DioException exp = err;
    try {
      final errorBody = err.response?.data as Map<String, dynamic>;
      exp = err.copyWith(error: FeralfileError.fromJson(errorBody['error']));
    } catch (e) {
      log.info(
          '[FeralfileAuthInterceptor] Can not parse . ${err.response?.data}');
      throw ErrorBindingException(
          message: '[FeralfileAuthInterceptor] Can not parse error for data:'
              ' ${err.response?.data}',
          originalException: err);
    } finally {
      handler.next(exp);
    }
  }
}

class HmacAuthInterceptor extends Interceptor {
  final String secretKey;

  HmacAuthInterceptor(this.secretKey);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.headers['X-Api-Signature'] == null) {
      final timestamp =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      String body = '';
      if (options.data is FormData || options.method.toUpperCase() == 'GET') {
        body = '';
      } else {
        body = bytesToHex(sha256
            .convert(options.data != null
                ? utf8.encode(json.encode(options.data))
                : [])
            .bytes);
      }
      final canonicalString = List<String>.of([
        options.path.split('?').first,
        body,
        timestamp,
      ]).join('|');
      final hmacSha256 = Hmac(sha256, utf8.encode(secretKey));
      final digest = hmacSha256.convert(utf8.encode(canonicalString));
      final sig = bytesToHex(digest.bytes);
      options.headers['X-Api-Signature'] = sig;
      options.headers['X-Api-Timestamp'] = timestamp;
    }
    handler.next(options);
  }
}

class AirdropInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    DioException exp = err;
    try {
      final errorBody = err.response?.data as Map<String, dynamic>;
      final json = errorBody['message'] != null
          ? jsonDecode(errorBody['message'])
          : errorBody;
      exp = err.copyWith(error: FeralfileError.fromJson(json['error']));
    } catch (e) {
      log.info("[AirdropInterceptor] Can't parse error. ${err.response?.data}");
      throw ErrorBindingException(
          message: '[AirdropInterceptor] Can not parse error for data:'
              ' ${err.response?.data}',
          originalException: err);
    } finally {
      handler.next(exp);
    }
  }
}

class ConnectingExceptionInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.isNetworkIssue) {
      log.warning('ConnectingExceptionInterceptor timeout');
      unawaited(injector<NetworkIssueManager>().showNetworkIssueWarning());
    }
    handler.next(err);
  }
}

class TVKeyInterceptor extends Interceptor {
  final String tvKey;

  TVKeyInterceptor(this.tvKey);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['API-KEY'] = tvKey;
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    DioException exp = err;
    try {
      final errorBody = err.response?.data as Map<String, dynamic>;
      exp = err.copyWith(error: FeralfileError.fromJson(errorBody['error']));
    } catch (e) {
      log.info(
          '[FeralfileAuthInterceptor] Can not parse . ${err.response?.data}');
      throw ErrorBindingException(
          message: '[FeralfileAuthInterceptor] Can not parse error for data:'
              ' ${err.response?.data}',
          originalException: err);
    } finally {
      handler.next(exp);
    }
  }
}
