
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'postcard_api.g.dart';

@RestApi(baseUrl: "")
abstract class PostcardApi {
  factory PostcardApi(Dio dio, {String baseUrl}) = _PostcardApi;

  @POST("/postcard/claim")
  Future claim(@Header("X-Api-Signature") String xApiSignature,
      @Body() Map<String, dynamic> body);

  @POST("/postcard/{token_id}/share")
  Future share(@Header("X-Api-Signature") String xApiSignature,
      @Path("token_id") String tokenId, @Body() Map<String, dynamic> body);

  @POST("/claim/{share_code}")
  Future claimShareCode(@Header("X-Api-Signature") String xApiSignature,
      @Path("share_code") String shareCode);

  @MultiPart()
  @POST("/postcard/{token_id}/stamp")
  Future<dynamic> updatePostcard({
    @Part(name: "image") required File data,
    @Part(name: "signature") required String signature,
    @Part(name: "timestamp") required int timestamp,
    @Part(name: "address") required String address,
    @Part(name: "publicKey") required String publicKey,
    @Part(name: "lat") double? lat,
    @Part(name: "lon") double? lon,
  });
}
