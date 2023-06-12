import 'dart:io';

import 'package:autonomy_flutter/service/memento_service.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'memento_api.g.dart';

@RestApi(baseUrl: "")
abstract class MementoApi {
  factory MementoApi(Dio dio, {String baseUrl}) = _MementoApi;

  @POST("/v1/claim/request")
  Future<MementoRequestClaimResponse> requestClaim(
      @Body() MementoRequestClaimRequest body);

  @POST("/v1/claim")
  Future<MementoClaimResponse> claim(@Body() MementoClaimRequest body);

  @GET("/v1/share/{share_code}")
  Future<MementoGetInfoResponse> getInfo(@Path("share_code") String shareCode);

  @POST("/v1/share/{token_id}")
  Future<MementoShareRespone> share(
      @Path("token_id") String tokenId, @Body() MementoShareRequest body);
}
