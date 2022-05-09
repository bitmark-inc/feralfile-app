// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iap_api.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

class _IAPApi implements IAPApi {
  _IAPApi(this._dio, {this.baseUrl});

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

  @override
  Future<JWT> auth(body) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body);
    final _result = await _dio.fetch<Map<String, dynamic>>(_setStreamType<JWT>(
        Options(method: 'POST', headers: _headers, extra: _extra)
            .compose(_dio.options, '/apis/v1/auth',
                queryParameters: queryParameters, data: _data)
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = JWT.fromJson(_result.data!);
    return value;
  }

  @override
  Future<dynamic> uploadProfile(requester, filename, appVersion, data) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'requester': requester};
    _headers.removeWhere((k, v) => v == null);
    final _data = FormData();
    _data.fields.add(MapEntry('filename', filename));
    _data.fields.add(MapEntry('appVersion', appVersion));
    _data.files.add(MapEntry(
        'data',
        MultipartFile.fromFileSync(data.path,
            filename: data.path.split(Platform.pathSeparator).last)));
    final _result = await _dio.fetch(_setStreamType<dynamic>(Options(
            method: 'POST',
            headers: _headers,
            extra: _extra,
            contentType: 'multipart/form-data')
        .compose(_dio.options, '/apis/v1/premium/profile-data',
            queryParameters: queryParameters, data: _data)
        .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = _result.data;
    return value;
  }

  @override
  Future<BackupVersions> getProfileVersions(requester, filename) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'filename': filename};
    final _headers = <String, dynamic>{r'requester': requester};
    _headers.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<BackupVersions>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/apis/v1/premium/profile-data/versions',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = BackupVersions.fromJson(_result.data!);
    return value;
  }

  @override
  Future<dynamic> deleteAllProfiles(requester) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'requester': requester};
    _headers.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch(_setStreamType<dynamic>(
        Options(method: 'DELETE', headers: _headers, extra: _extra)
            .compose(_dio.options, '/apis/v1/premium/profile-data',
                queryParameters: queryParameters, data: _data)
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = _result.data;
    return value;
  }

  @override
  Future<OnesignalIdentityHash> generateIdentityHash(body) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body);
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<OnesignalIdentityHash>(
            Options(method: 'POST', headers: _headers, extra: _extra)
                .compose(_dio.options, '/apis/v1/me/identity-hash',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = OnesignalIdentityHash.fromJson(_result.data!);
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
