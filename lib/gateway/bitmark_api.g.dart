// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bitmark_api.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

class _BitmarkApi implements BitmarkApi {
  _BitmarkApi(this._dio, {this.baseUrl}) {
    baseUrl ??= 'https://api.test.bitmark.com/';
  }

  final Dio _dio;

  String? baseUrl;

  @override
  Future<Map<String, List<Bitmark>>> getBitmarkIDs(
      owner, includePending) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'owner': owner,
      r'pending': includePending
    };
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Map<String, List<Bitmark>>>(
            Options(method: 'GET', headers: <String, dynamic>{}, extra: _extra)
                .compose(_dio.options, '/v1/bitmarks',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    var value = _result.data!.map((k, dynamic v) => MapEntry(
        k,
        (v as List)
            .map((i) => Bitmark.fromJson(i as Map<String, dynamic>))
            .toList()));
    return value;
  }

  @override
  Future<Map<String, Bitmark>> getBitmarkAssetInfo(
      id, includePending, provenance) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'pending': includePending,
      r'provenance': provenance
    };
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Map<String, Bitmark>>(
            Options(method: 'GET', headers: <String, dynamic>{}, extra: _extra)
                .compose(_dio.options, '/v1/bitmarks/$id',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    var value = _result.data!.map((k, dynamic v) =>
        MapEntry(k, Bitmark.fromJson(v as Map<String, dynamic>)));
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
