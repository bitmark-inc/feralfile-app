//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/asset_price.dart';
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

  @POST("/api/asset-prices")
  Future<Map<String, List<AssetPrice>>> getAssetPrice(
      @Body() Map<String, List<String>> body);

  @GET("/api/exhibitions/{exhibitionId}")
  Future<ExhibitionResponse> getExhibition(@Path("exhibitionId") String exhibitionId);

  @POST("/api/exhibitions/{exhibitionId}/claim")
  Future<TokenClaimResponse> claimToken(
    @Path("exhibitionId") String exhibitionId,
    @Body() Map<String, dynamic> body,
  );
}
