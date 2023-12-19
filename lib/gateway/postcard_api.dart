import 'dart:io';

import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/model/prompt.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/leaderboard/postcard_leaderboard.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_page.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:retrofit/retrofit.dart';

part 'postcard_api.g.dart';

@RestApi(baseUrl: '')
abstract class PostcardApi {
  factory PostcardApi(Dio dio, {String baseUrl}) = _PostcardApi;

  @POST('/v1/postcard/claim')
  Future<ClaimPostCardResponse> claim(@Body() ClaimPostCardRequest body);

  @POST('/v1/postcard/claim/request')
  Future<RequestPostcardResponse> request(@Body() RequestPostcardRequest body);

  @POST('/v1/postcard/claim')
  Future<ReceivePostcardResponse> receive(@Body() Map<String, dynamic> body);

  @POST('/v1/postcard/{token_id}/share')
  Future share(
      @Path('token_id') String tokenId, @Body() Map<String, dynamic> body);

  @GET('/v1/postcard/claim/{share_code}')
  Future claimShareCode(@Path('share_code') String shareCode);

  @GET('/v1/postcard/{token_id}/merchandise_enabled')
  Future<String> getMerchandiseEnable(@Path('token_id') String tokenId);

  @MultiPart()
  @POST('/v1/postcard/{token_id}/stamp')
  Future<dynamic> updatePostcard({
    @Path('token_id') required String tokenId,
    @Part(name: 'image') required File data,
    @Part(name: 'metadata') required File metadata,
    @Part(name: 'signature') required String signature,
    @Part(name: 'address') required String address,
    @Part(name: 'publicKey') required String publicKey,
    @Part(name: 'counter') required int counter,
    @Part(name: 'lat') double? lat,
    @Part(name: 'lon') double? lon,
    @Part(name: 'promptID') String? promptID,
    @Part(name: 'prompt') String? prompt,
  });

  @GET('/v1/leaderboard')
  Future<GetLeaderboardResponse> getLeaderboard(@Query('unit') String unit,
      @Query('size') int size, @Query('offset') int offset);

  @GET('/v1/postcard/{token_id}/prompts')
  Future<List<Prompt>> getPrompts(@Path('token_id') String tokenId);
}

class GetLeaderboardResponse {
  List<PostcardLeaderboardItem> items;

  GetLeaderboardResponse(this.items);

  factory GetLeaderboardResponse.fromJson(Map<String, dynamic> map) {
    final listPostcard = map['postcards'] as List<dynamic>;
    return GetLeaderboardResponse(List<PostcardLeaderboardItem>.from(
        listPostcard.mapIndexed((index, element) =>
            PostcardLeaderboardItem.fromJson(
                element..addEntries([MapEntry('rank', index + 1)])))));
  }

  //toJson method
  Map<String, dynamic> toJson() => {
        'postcards': items.map((x) => x.toJson()).toList(),
      };
}
