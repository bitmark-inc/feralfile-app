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
}
