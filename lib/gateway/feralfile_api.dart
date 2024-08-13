//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_list_response.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/model/ff_user.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'feralfile_api.g.dart';

@RestApi(baseUrl: '')
abstract class FeralFileApi {
  factory FeralFileApi(Dio dio, {String baseUrl}) = _FeralFileApi;

  @GET('/api/exhibitions/{exhibitionId}')
  Future<ExhibitionResponse> getExhibition(
      @Path('exhibitionId') String exhibitionId,
      {@Query('includeFirstArtwork') bool includeFirstArtwork = false});

  @GET('/api/series/{seriesId}')
  Future<FFSeriesResponse> getSeries({
    @Path('seriesId') required String seriesId,
    @Query('includeFiles') bool includeFiles = true,
    @Query('includeCollectibility') bool includeCollectibility = true,
    @Query('includeUniqueFilePath') bool includeUniqueFilePath = true,
    @Query('includeFirstArtwork') bool includeFirstArtwork = true,
  });

  @GET('/api/series')
  Future<FFListSeriesResponse> getListSeries({
    @Query('exhibitionID') required String exhibitionID,
    @Query('sortBy') String? sortBy,
    @Query('sortOrder') String? sortOrder,
    @Query('includeArtist') bool includeArtist = true,
    @Query('includeUniqueFilePath') bool includeUniqueFilePath = true,
  });

  @GET('/api/exhibitions/{exhibitionID}/revenue-setting/resale')
  Future<ResaleResponse> getResaleInfo(
      @Path('exhibitionID') String exhibitionID);

  @GET('/api/artworks/{tokenID}')
  Future<ArtworkResponse> getArtworks(
    @Path('tokenID') String tokenID, {
    @Query('includeSeries') bool includeSeries = true,
    @Query('includeExhibition') bool includeExhibition = true,
    @Query('includeArtist') bool includeArtist = true,
  });

  @GET('/api/exhibitions')
  Future<ListExhibitionResponse> getAllExhibitions({
    @Query('sortBy') String? sortBy,
    @Query('sortOrder') String? sortOrder,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('keyword') String? keyword,
  });

  @GET('/api/exhibitions/featured')
  Future<ExhibitionResponse> getFeaturedExhibition();

  @GET('/api/artworks/featured')
  Future<FFListArtworksResponse> getFeaturedArtworks({
    @Query('includeArtist') bool includeArtist = true,
    @Query('includeExhibition') bool includeExhibition = true,
    @Query('includeExhibitionContract') bool includeExhibitionContract = true,
  });

  @GET('/api/exhibitions/upcoming')
  Future<ExhibitionResponse> getUpcomingExhibition();

  @GET('/api/artworks')
  Future<FeralFileListResponse<Artwork>> getListArtworks({
    @Query('exhibitionID') String? exhibitionId,
    @Query('seriesID') String? seriesId,
    @Query('offset') int? offset = 0,
    @Query('limit') int? limit = 1,
    @Query('includeActiveSwap') bool includeActiveSwap = true,
    @Query('sortBy') String sortBy = 'index',
    @Query('sortOrder') String sortOrder = 'ASC',
    @Query('isViewable') bool? isViewable,
    @Query('filterBurned') bool? filterBurned,
  });

  @POST('/api/web3/messages/action')
  Future<ActionMessageResponse> getActionMessage(
    @Body() Map<String, dynamic> body,
  );

  @GET('/api/artworks/{artworkId}/download-url')
  Future<FeralFileResponse<String>> getDownloadUrl(
    @Path('artworkId') String artworkId,
    @Header('Web3Token') String web3Token,
    @Header('X-FF-Signer') String signer,
  );

  @GET('/api/series')
  Future<FeralFileListResponse<FFSeries>> exploreArtwork({
    @Query('sortBy') String? sortBy,
    @Query('sortOrder') String? sortOrder,
    @Query('limit') int limit = 20,
    @Query('offset') int offset = 0,
    @Query('includeArtist') bool includeArtist = true,
    @Query('includeExhibition') bool includeExhibition = true,
    @Query('includeFirstArtwork') bool includeFirstArtwork = true,
    @Query('onlyViewable') bool onlyViewable = true,
    @Query('keyword') String keyword = '',
  });

  @GET('/api/artists')
  Future<FeralFileListResponse<FFArtist>> getArtists({
    @Query('limit') int limit = 20,
    @Query('offset') int offset = 0,
    @Query('sortBy') String sortBy = 'relevance',
    @Query('sortOrder') String sortOrder = 'DESC',
    @Query('keyword') String keyword = '',
    @Query('unique') bool unique = true,
  });

  // get https://feralfile.com/api/curators?limit=50&offset=0&sortBy=relevance&sortOrder=DESC&keyword=hihi&unique=true&excludedFF=true
  @GET('/api/curators')
  Future<FeralFileListResponse<FFCurator>> getCurators({
    @Query('limit') int limit = 20,
    @Query('offset') int offset = 0,
    @Query('sortBy') String sortBy = 'relevance',
    @Query('sortOrder') String sortOrder = 'DESC',
    @Query('keyword') String keyword = '',
    @Query('unique') bool unique = true,
    @Query('excludedFF') bool excludedFF = true,
  });

  @GET('/api/exploration/statistics')
  Future<ExploreStatisticsData> getExploreStatistics({
    @Query('unique') bool unique = true,
    @Query('excludedFF') bool excludedFF = true,
  });
}

class ActionMessageResponse {
  String message;

  ActionMessageResponse({required this.message});

  factory ActionMessageResponse.fromJson(Map<String, dynamic> json) =>
      ActionMessageResponse(
        message: json['result']['message'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'result': {'message': message},
      };
}

class FFListSeriesResponse {
  List<FFSeries> result;

  FFListSeriesResponse({required this.result});

  factory FFListSeriesResponse.fromJson(Map<String, dynamic> json) =>
      FFListSeriesResponse(
        result:
            (json['result'] as List).map((e) => FFSeries.fromJson(e)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'result': result,
      };
}

class FFListArtworksResponse {
  List<Artwork> result;

  FFListArtworksResponse({required this.result});

  factory FFListArtworksResponse.fromJson(Map<String, dynamic> json) =>
      FFListArtworksResponse(
        result:
            (json['result'] as List).map((e) => Artwork.fromJson(e)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'result': result,
      };
}

class FeralFileResponse<T> {
  T result;

  FeralFileResponse({required this.result});

  factory FeralFileResponse.fromJson(Map<String, dynamic> json) =>
      FeralFileResponse(
        result: json['result'],
      );

  Map<String, dynamic> toJson() => {
        'result': result,
      };
}
