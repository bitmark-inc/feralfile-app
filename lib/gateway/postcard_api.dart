import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'postcard_api.g.dart';

@RestApi(baseUrl: "")
abstract class PostcardApi {
  factory PostcardApi(Dio dio, {String baseUrl}) = _PostcardApi;

  @POST("/postcard/claim")
  Future claim(@Body() Map<String, dynamic> body);
}
