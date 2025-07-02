import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'mobile_controller_api.g.dart';

@RestApi(baseUrl: 'https://artwork-info.bitmark-development.workers.dev')
abstract class MobileControllerAPI {
  factory MobileControllerAPI(Dio dio, {String baseUrl}) = _MobileControllerAPI;

  @POST('/intent-parser/text')
  Future<Map<String, dynamic>> getDP1CallFromText(
    @Body() Map<String, dynamic> body,
  );

  @POST('/intent-parser/voice')
  Future<Map<String, dynamic>> getDP1CallFromVoice(
    @Body() Map<String, dynamic> body,
    @Query('stream') bool withStream,
  );

  @POST('/intent-parser/voice')
  @DioResponseType(ResponseType.stream)
  Future<Stream<dynamic>> getDP1CallFromVoiceStream(
    @Body() Map<String, dynamic> body,
    @Query('stream') bool withStream,
  );
}
