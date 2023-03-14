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

  @GET("/api/accounts/me?includeWyre=true")
  @CacheControl(noCache: true)
  Future<Map<String, FFAccount>> getAccount(
      @Header("Authorization") String bearerToken);

  @GET("/api/exhibitions/{exhibitionId}")
  Future<ExhibitionResponse> getExhibition(
    @Path("exhibitionId") String exhibitionId, {
    @Query("includeArtwork") bool includeArtwork = true,
  });

  @GET("/api/artworks/{artworkId}")
  Future<FFArtworkResponse> getArtwork(@Path("artworkId") String artworkId);

  @POST("/api/artworks/{artworkId}/claim")
  Future<TokenClaimResponse> claimArtwork(
    @Path("artworkId") String artworkId,
    @Body() Map<String, dynamic> body,
  );

  @GET("/api/exhibitions/{exhibitionID}/revenue-setting/resale")
  Future<ResaleResponse> getResaleInfo(
      @Path("exhibitionID") String exhibitionID);

  @GET("/api/artwork-editions/{tokenID}/{exhibitionID}")
  Future<ArtworkEditionResponse> getArtworkEditions(
    @Path("tokenID") String tokenID, {
    @Query("includeArtwork") bool includeArtwork = true,
    @Query("includeExhibition") bool includeExhibition = true,
    @Query("includeArtist") bool includeArtist = true,
  });
}
