import 'dart:io';

import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_page.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../model/postcard_claim.dart';

part 'postcard_api.g.dart';

@RestApi(baseUrl: "")
abstract class PostcardApi {
  factory PostcardApi(Dio dio, {String baseUrl}) = _PostcardApi;

  @POST("/v1/postcard/claim")
  Future<ClaimPostCardResponse> claim(@Body() ClaimPostCardRequest body);

  @POST("/v1/postcard/claim/request")
  Future<RequestPostcardResponse> request(@Body() RequestPostcardRequest body);

  @POST("/v1/postcard/claim")
  Future<ReceivePostcardResponse> receive(@Body() Map<String, dynamic> body);

  @POST("/v1/postcard/{token_id}/share")
  Future share(
      @Path("token_id") String tokenId, @Body() Map<String, dynamic> body);

  @GET("/v1/postcard/claim/{share_code}")
  Future claimShareCode(@Path("share_code") String shareCode);

  @MultiPart()
  @POST("/v1/postcard/{token_id}/stamp")
  Future<dynamic> updatePostcard({
    @Path("token_id") required String tokenId,
    @Part(name: "image") required File data,
    @Part(name: "metadata") required File metadata,
    @Part(name: "signature") required String signature,
    @Part(name: "address") required String address,
    @Part(name: "publicKey") required String publicKey,
    @Part(name: "lat") double? lat,
    @Part(name: "lon") double? lon,
    @Part(name: "counter") required int counter,
  });

  @GET("/v1/leaderboard?unit={unit}")
  Future<GetLeaderboardResponse> getLeaderboard(@Path("unit") String unit);
}

class GetLeaderboardResponse {
  List<PostcardLeaderboardItem> items;

  GetLeaderboardResponse(this.items);

  factory GetLeaderboardResponse.fromJson(Map<String, dynamic> map) {
    final listPostcard = map['postcards'] as List<dynamic>;
    return GetLeaderboardResponse(List<PostcardLeaderboardItem>.from(
        listPostcard.mapIndexed((index, element) =>
            PostcardLeaderboardItem.fromJson(
                element..addEntries([MapEntry("rank", index + 1)])))));
  }

  //toJson method
  Map<String, dynamic> toJson() {
    return {
      'postcards': items.map((x) => x.toJson()).toList(),
    };
  }
}
