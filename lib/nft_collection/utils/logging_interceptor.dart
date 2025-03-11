import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:autonomy_flutter/nft_collection/nft_collection.dart';

class LoggingInterceptor extends Interceptor {
  LoggingInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final curl = cURLRepresentation(err.requestOptions);
    final message = err.message;
    NftCollection.apiLog.info('API Request: $curl');
    NftCollection.apiLog.warning('Respond error: $message');
    return handler.next(err);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    handler.next(response);
    writeAPILog(response);
  }

  Future<void> writeAPILog(Response response) async {
    final curl = cURLRepresentation(response.requestOptions);
    NftCollection.apiLog.info('API Request: $curl');
    NftCollection.apiLog.info('API Response: ${response.headers}');
  }

  String cURLRepresentation(RequestOptions options) {
    final components = <String>[r'$ curl -i'];
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
