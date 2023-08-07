//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'feralfile_api.g.dart';

@RestApi(baseUrl: "")
abstract class FeralFileApi {
  factory FeralFileApi(Dio dio, {String baseUrl}) = _FeralFileApi;

  @GET("/api/exhibitions/{exhibitionId}")
  Future<ExhibitionResponse> getExhibition(
      @Path("exhibitionId") String exhibitionId);

  @GET("/api/series/{seriesId}")
  Future<FFSeriesResponse> getSeries(@Path("seriesId") String seriesId);

  @POST("/api/series/{seriesId}/claim")
  Future<TokenClaimResponse> claimSeries(
    @Path("seriesId") String seriesId,
    @Body() Map<String, dynamic> body,
  );

  @GET("/api/exhibitions/{exhibitionID}/revenue-setting/resale")
  Future<ResaleResponse> getResaleInfo(
      @Path("exhibitionID") String exhibitionID);

  @GET("/api/artworks/{tokenID}")
  Future<ArtworkResponse> getArtworks(
    @Path("tokenID") String tokenID, {
    @Query("includeSeries") bool includeSeries = true,
    @Query("includeExhibition") bool includeExhibition = true,
    @Query("includeArtist") bool includeArtist = true,
  });
}
