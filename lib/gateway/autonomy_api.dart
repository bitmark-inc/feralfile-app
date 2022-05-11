import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'autonomy_api.g.dart';

@RestApi(baseUrl: "")
abstract class AutonomyApi {
  factory AutonomyApi(Dio dio, {String baseUrl}) = _AutonomyApi;

  @POST("/apis/v1/me/link-addresses")
  Future postLinkedAddressed(@Body() Map<String, List<String>> body);
}
