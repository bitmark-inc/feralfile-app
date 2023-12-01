import 'package:dio/dio.dart';
import 'package:retrofit/http.dart';

part 'chat_api.g.dart';

@RestApi(baseUrl: '')
abstract class ChatApi {
  factory ChatApi(Dio dio, {String baseUrl}) = _ChatApi;

  @POST('/v1/auth')
  Future<ChatAuthResponse> getToken(
    @Body() Map<String, dynamic> body,
  );
}

class ChatAuthResponse {
  final String token;

  ChatAuthResponse(this.token);

  factory ChatAuthResponse.fromJson(Map<String, dynamic> json) {
    return ChatAuthResponse(json['token']);
  }
}
