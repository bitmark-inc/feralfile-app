// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indexer_api.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

class _IndexerApi implements IndexerApi {
  _IndexerApi(this._dio, {this.baseUrl});

  final Dio _dio;

  String? baseUrl;

  Network get _networkFromBaseURL {
    return baseUrl?.contains("test") ?? true
        ? Network.TESTNET
        : Network.MAINNET;
  }

  @override
  Future<List<Asset>> getNftTokens(ids) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(ids);
    final _result = await _dio.fetch<List<dynamic>>(_setStreamType<List<Asset>>(
        Options(method: 'POST', headers: _headers, extra: _extra)
            .compose(_dio.options, '/nft/query',
                queryParameters: queryParameters, data: _data)
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    var value = _result.data!
        .map((dynamic i) =>
            Asset.fromJson(i as Map<String, dynamic>, _networkFromBaseURL))
        .toList();
    return value;
  }

  @override
  Future<List<Asset>> getNFTTokens(offset) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'offset': offset};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<List<dynamic>>(_setStreamType<List<Asset>>(
        Options(method: 'POST', headers: _headers, extra: _extra)
            .compose(_dio.options, '/nft/query',
                queryParameters: queryParameters, data: _data)
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    var value = _result.data!
        .map((dynamic i) =>
            Asset.fromJson(i as Map<String, dynamic>, _networkFromBaseURL))
        .toList();
    return value;
  }

  @override
  Future<List<Asset>> getNftTokensByOwner(owner, offset, size) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'owner': owner,
      r'offset': offset,
      r'size': size
    };
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<List<dynamic>>(_setStreamType<List<Asset>>(
        Options(method: 'GET', headers: _headers, extra: _extra)
            .compose(_dio.options, '/nft',
                queryParameters: queryParameters, data: _data)
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    var value = _result.data!
        .map((dynamic i) =>
            Asset.fromJson(i as Map<String, dynamic>, _networkFromBaseURL))
        .toList();
    return value;
  }

  @override
  Future<dynamic> requestIndex(payload) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(payload);
    final _result = await _dio.fetch(_setStreamType<dynamic>(
        Options(method: 'POST', headers: _headers, extra: _extra)
            .compose(_dio.options, '/nft/index',
                queryParameters: queryParameters, data: _data)
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = _result.data;
    return value;
  }

  @override
  Future<BlockchainIdentity> getIdentity(accountNumber) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<BlockchainIdentity>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/identity/${accountNumber}',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = BlockchainIdentity.fromJson(_result.data!);
    return value;
  }

  @override
  Future<List<String>> getNftIDsByOwner(owner) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'owner': owner};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<List<dynamic>>(
        _setStreamType<List<String>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/nft/owned',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = _result.data!.cast<String>();
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
