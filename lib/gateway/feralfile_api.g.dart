// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feralfile_api.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

class _FeralFileApi implements FeralFileApi {
  _FeralFileApi(this._dio, {this.baseUrl}) {
    baseUrl ??= 'https://feralfile1.dev.bitmark.com/';
  }

  final Dio _dio;

  String? baseUrl;

  @override
  Future<Map<String, Account>> getAccount(bearerToken) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Map<String, Account>>(Options(
                method: 'GET',
                headers: <String, dynamic>{r'Authorization': bearerToken},
                extra: _extra)
            .compose(_dio.options, '/api/accounts/me',
                queryParameters: queryParameters, data: _data)
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    var value = _result.data!.map((k, dynamic v) =>
        MapEntry(k, Account.fromJson(v as Map<String, dynamic>)));
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
