// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iap_api.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

class _IAPApi implements IAPApi {
  _IAPApi(this._dio, {this.baseUrl}) {
    baseUrl ??= 'https://autonomy-auth.test.bitmark.com';
  }

  final Dio _dio;

  String? baseUrl;

  @override
  Future<JWT> verifyIAP(body) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body);
    final _result = await _dio.fetch<Map<String, dynamic>>(_setStreamType<JWT>(
        Options(method: 'POST', headers: _headers, extra: _extra)
            .compose(_dio.options, '/auth',
                queryParameters: queryParameters, data: _data)
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = JWT.fromJson(_result.data!);
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
