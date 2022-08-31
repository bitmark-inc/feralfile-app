// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tzkt_api.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

class _TZKTApi implements TZKTApi {
  _TZKTApi(this._dio, {this.baseUrl}) {
    baseUrl ??= 'https://api.tzkt.io';
  }

  final Dio _dio;

  String? baseUrl;

  @override
  Future<List<TZKTOperation>> getOperations(address,
      {type = "transaction",
      quote = "usd",
      sort = 1,
      limit = 100,
      lastId,
      initiator}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'type': type,
      r'quote': quote,
      r'sort': sort,
      r'limit': limit,
      r'lastId': lastId,
      r'initiator.ne': initiator
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<List<dynamic>>(
        _setStreamType<List<TZKTOperation>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/v1/accounts/${address}/operations',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    var value = _result.data!
        .map((dynamic i) => TZKTOperation.fromJson(i as Map<String, dynamic>))
        .toList();
    return value;
  }

  @override
  Future<List<TZKTTokenTransfer>> getTokenTransfer(
      {
        anyOf,
        sort = "id",
        limit = 100,
        lastId
      }) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'anyof.from.to': anyOf,
      r'sort.desc': sort,
      r'limit': limit,
      r'lastId': lastId,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<List<dynamic>>(
        _setStreamType<List<TZKTOperation>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/v1/tokens/transfers',
                queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    var value = _result.data!
        .map((dynamic i) => TZKTTokenTransfer.fromJson(i as Map<String, dynamic>))
        .toList();
    return value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }
}
