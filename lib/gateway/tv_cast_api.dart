import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'tv_cast_api.g.dart';

@RestApi(baseUrl: '')
abstract class TvCastApi {
  factory TvCastApi(Dio dio, {String baseUrl}) = _TvCastApi;

  @GET('/api/cast')
  Future<dynamic> request({
    @Query('topicID') required String topicId,
    @Body() required Map<String, dynamic> body,
  });
}
