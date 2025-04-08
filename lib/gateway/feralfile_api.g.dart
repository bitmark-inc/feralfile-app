// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feralfile_api.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers

class _FeralFileApi implements FeralFileApi {
  _FeralFileApi(
    this._dio, {
    this.baseUrl,
  });

  final Dio _dio;

  String? baseUrl;

  @override
  Future<ExhibitionResponse> getExhibition(
    String exhibitionId, {
    bool includeFirstArtwork = false,
  }) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'includeFirstArtwork': includeFirstArtwork
    };
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<ExhibitionResponse>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/api/exhibitions/${exhibitionId}',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = ExhibitionResponse.fromJson(_result.data!);
    return value;
  }

  @override
  Future<FFSeriesResponse> getSeries({
    required String seriesId,
    bool includeFiles = true,
    bool includeCollectibility = true,
    bool includeUniqueFilePath = true,
    bool includeFirstArtwork = true,
  }) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'includeFiles': includeFiles,
      r'includeCollectibility': includeCollectibility,
      r'includeUniqueFilePath': includeUniqueFilePath,
      r'includeFirstArtwork': includeFirstArtwork,
    };
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<FFSeriesResponse>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/api/series/${seriesId}',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = FFSeriesResponse.fromJson(_result.data!);
    return value;
  }

  @override
  Future<FFListSeriesResponse> getListSeries({
    required String exhibitionID,
    String? sortBy,
    String? sortOrder,
    bool includeArtist = true,
    bool includeUniqueFilePath = true,
  }) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'exhibitionID': exhibitionID,
      r'sortBy': sortBy,
      r'sortOrder': sortOrder,
      r'includeArtist': includeArtist,
      r'includeUniqueFilePath': includeUniqueFilePath,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<FFListSeriesResponse>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/api/series',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = FFListSeriesResponse.fromJson(_result.data!);
    return value;
  }

  @override
  Future<ResaleResponse> getResaleInfo(String exhibitionID) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<ResaleResponse>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/api/exhibitions/${exhibitionID}/revenue-setting/resale',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = ResaleResponse.fromJson(_result.data!);
    return value;
  }

  @override
  Future<ArtworkResponse> getArtworks(
    String tokenID, {
    bool includeSeries = true,
    bool includeExhibition = true,
    bool includeArtist = true,
  }) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'includeSeries': includeSeries,
      r'includeExhibition': includeExhibition,
      r'includeArtist': includeArtist,
    };
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<ArtworkResponse>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/api/artworks/${tokenID}',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = ArtworkResponse.fromJson(_result.data!);
    return value;
  }

  @override
  Future<ListExhibitionResponse> getAllExhibitions({
    String? sortBy,
    String? sortOrder,
    int? limit,
    int? offset,
    String? keyword,
    List<String> relatedAlumniAccountIDs = const [],
    Map<String, dynamic> customQueryParam = const {},
  }) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'sortBy': sortBy,
      r'sortOrder': sortOrder,
      r'limit': limit,
      r'offset': offset,
      r'keyword': keyword,
      r'relatedAlumniAccountIDs': relatedAlumniAccountIDs,
    };
    // add customQueryParams
    queryParameters.addAll(customQueryParam);
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<ListExhibitionResponse>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/api/exhibitions',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = ListExhibitionResponse.fromJson(_result.data!);
    return value;
  }

  @override
  Future<ExhibitionResponse> getFeaturedExhibition() async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<ExhibitionResponse>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/api/exhibitions/featured',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = ExhibitionResponse.fromJson(_result.data!);
    return value;
  }

  @override
  Future<FFListArtworksResponse> getFeaturedArtworks({
    bool includeArtist = true,
    bool includeExhibition = true,
    bool includeExhibitionContract = true,
    bool includeSuccessfulSwap = true,
  }) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'includeArtist': includeArtist,
      r'includeExhibition': includeExhibition,
      r'includeExhibitionContract': includeExhibitionContract,
      r'includeSuccessfulSwap': includeSuccessfulSwap,
    };
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<FFListArtworksResponse>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/api/artworks/featured',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = FFListArtworksResponse.fromJson(_result.data!);
    return value;
  }

  @override
  Future<ExhibitionResponse> getUpcomingExhibition() async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<ExhibitionResponse>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/api/exhibitions/upcoming',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = ExhibitionResponse.fromJson(_result.data!);
    return value;
  }

  @override
  Future<FeralFileListResponse<Artwork>> getListArtworks({
    String? exhibitionId,
    String? seriesId,
    int? offset = 0,
    int? limit = 1,
    bool includeActiveSwap = true,
    String sortBy = 'index',
    String sortOrder = 'ASC',
    bool? isViewable,
    bool? filterBurned,
  }) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'exhibitionID': exhibitionId,
      r'seriesID': seriesId,
      r'offset': offset,
      r'limit': limit,
      r'includeActiveSwap': includeActiveSwap,
      r'sortBy': sortBy,
      r'sortOrder': sortOrder,
      r'isViewable': isViewable,
      r'filterBurned': filterBurned,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<FeralFileListResponse<Artwork>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/api/artworks',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = FeralFileListResponse<Artwork>.fromJson(
        _result.data!, Artwork.fromJson);
    return value;
  }

  @override
  Future<FeralFileListResponse<DailyToken>> getDailiesToken({
    int? offset = 0,
    int? limit = 1,
    bool? includeSuccessfulSwap = true,
    String? startDate,
  }) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'offset': offset,
      r'limit': limit,
      r'includeSuccessfulSwap': includeSuccessfulSwap,
      r'startDate': startDate,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<FeralFileListResponse<DailyToken>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/api/dailies/upcoming',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = FeralFileListResponse<DailyToken>.fromJson(
        _result.data!, DailyToken.fromJson);
    return value;
  }

  @override
  Future<FeralFileListResponse<DailyToken>> getDailiesTokenByDate({
    required String date,
    bool? includeSuccessfulSwap = true,
  }) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'includeSuccessfulSwap': includeSuccessfulSwap
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<FeralFileListResponse<DailyToken>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/api/dailies/date/${date}',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = FeralFileListResponse<DailyToken>.fromJson(
        _result.data!, DailyToken.fromJson);
    return value;
  }

  @override
  Future<FeralFileListResponse<FFSeries>> exploreArtwork({
    String? sortBy,
    String? sortOrder,
    int limit = 20,
    int offset = 0,
    bool includeArtist = true,
    bool includeExhibition = true,
    bool includeFirstArtwork = true,
    bool onlyViewable = true,
    String keyword = '',
    List<String> artistAlumniAccountIDs = const [],
    bool includeUniqueFilePath = true,
    Map<String, dynamic> customQueryParam = const {},
  }) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'sortBy': sortBy,
      r'sortOrder': sortOrder,
      r'limit': limit,
      r'offset': offset,
      r'includeArtist': includeArtist,
      r'includeExhibition': includeExhibition,
      r'includeFirstArtwork': includeFirstArtwork,
      r'onlyViewable': onlyViewable,
      r'keyword': keyword,
      r'artistAlumniAccountIDs': artistAlumniAccountIDs,
      r'includeUniqueFilePath': includeUniqueFilePath,
    };
    // add customQueryParams
    queryParameters.addAll(customQueryParam);
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<FeralFileListResponse<FFSeries>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/api/series',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = FeralFileListResponse<FFSeries>.fromJson(
        _result.data!, FFSeries.fromJson);
    return value;
  }

  @override
  Future<FeralFileListResponse<AlumniAccount>> getListAlumni({
    int limit = 20,
    int offset = 0,
    String sortBy = 'relevance',
    String sortOrder = 'DESC',
    String keyword = '',
    bool isArtist = false,
    bool isCurator = false,
    bool unique = true,
    bool excludedFF = true,
  }) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'limit': limit,
      r'offset': offset,
      r'sortBy': sortBy,
      r'sortOrder': sortOrder,
      r'keyword': keyword,
      r'isArtist': isArtist,
      r'isCurator': isCurator,
      r'unique': unique,
      r'excludedFF': excludedFF,
    };
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<FeralFileListResponse<AlumniAccount>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/api/alumni',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = FeralFileListResponse<AlumniAccount>.fromJson(
        _result.data!, AlumniAccount.fromJson);
    return value;
  }

  @override
  Future<ExploreStatisticsData> getExploreStatistics({
    bool unique = true,
    bool excludedFF = true,
  }) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'unique': unique,
      r'excludedFF': excludedFF,
    };
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<ExploreStatisticsData>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/api/exploration/statistics',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = ExploreStatisticsData.fromJson(
        _result.data!['result'] as Map<String, dynamic>);
    return value;
  }

  @override
  Future<FeralFileResponse<AlumniAccount>> getAlumni({
    String alumniID = '',
    bool includeCollaborationAlumniAccounts = true,
  }) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'includeCollaborationAlumniAccounts': includeCollaborationAlumniAccounts
    };
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<FeralFileResponse<AlumniAccount>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/api/alumni/${alumniID}',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = FeralFileResponse<AlumniAccount>.fromJson(_result.data!,
        fromJson: AlumniAccount.fromJson);
    return value;
  }

  @override
  Future<FeralFileListResponse<Post>> getPosts({
    String sortBy = 'dateTime',
    String sortOrder = 'DESC',
    List<String> types = const [],
    List<String> relatedAlumniAccountIDs = const [],
    bool includeExhibition = true,
  }) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'sortBy': sortBy,
      r'sortOrder': sortOrder,
      r'types': types,
      r'relatedAlumniAccountIDs': relatedAlumniAccountIDs,
      r'includeExhibition': includeExhibition,
    };
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<FeralFileListResponse<Post>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/api/posts',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value =
        FeralFileListResponse<Post>.fromJson(_result.data!, Post.fromJson);
    return value;
  }

  @override
  Future<List<String>> getIndexerAssetIds({
    required String seriesId,
  }) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<FeralFileListResponse<String>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/api/series/${seriesId}/indexer-asset-ids',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = List<String>.from(_result.data!['result'] as List);
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

  String _combineBaseUrls(
    String dioBaseUrl,
    String? baseUrl,
  ) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }
}
