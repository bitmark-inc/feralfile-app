import 'package:autonomy_flutter/model/jwt.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'iap_api.g.dart';

@RestApi(baseUrl: "https://autonomy-auth.test.bitmark.com")
abstract class IAPApi {
  factory IAPApi(Dio dio, {String baseUrl}) = _IAPApi;

  @POST("/auth")
  Future<JWT> verifyIAP(@Body() Map<String, String> body);
}
