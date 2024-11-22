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

  @POST('/v1/chat/aliases')
  Future<SetChatAliasResponse> setAlias(
    @Body() Map<String, dynamic> body,
    @Header('Authorization') String authorization,
  );

  @GET('/v1/chat/aliases')
  Future<GetChatAliasResponse> getAlias(
    @Query('index_id') String indexId,
    @Header('Authorization') String authorization,
  );
}

class ChatAuthResponse {
  final String token;

  ChatAuthResponse(this.token);
  factory ChatAuthResponse.fromJson(Map<String, dynamic> json) =>
      ChatAuthResponse(json['token'] as String);
}

class SetChatAliasResponse {
  final Map<String, String> aliases;

  SetChatAliasResponse(this.aliases);

  factory SetChatAliasResponse.fromJson(Map<String, dynamic> json) =>
      SetChatAliasResponse(json['aliases'] as Map<String, String>);
}

class GetChatAliasResponse {
  final List<ChatAlias> aliases;

  GetChatAliasResponse(this.aliases);

  factory GetChatAliasResponse.fromJson(Map<String, dynamic> json) =>
      GetChatAliasResponse((json['aliases'] as List)
          .map((e) => ChatAlias.fromJson(e as Map<String, dynamic>))
          .toList());
}

class ChatAlias {
  final String address;
  final String alias;
  final String groupID;

  ChatAlias(
      {required this.address, required this.alias, required this.groupID});

  factory ChatAlias.fromJson(Map<String, dynamic> json) => ChatAlias(
      address: json['address'] as String,
      alias: json['alias'] as String,
      groupID: json['groupID'] as String);

  Map<String, dynamic> toJson() => {
        'address': address,
        'alias': alias,
        'groupID': groupID,
      };
}
