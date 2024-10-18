import 'package:dio/dio.dart';
import 'package:retrofit/http.dart';

part 'remote_config_api.g.dart';

@RestApi(baseUrl: '')
abstract class RemoteConfigApi {
  factory RemoteConfigApi(Dio dio, {String baseUrl}) = _RemoteConfigApi;

  @GET('/app.json')
  Future<String> getConfigs();
}
