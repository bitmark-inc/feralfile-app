import 'package:autonomy_flutter/model/feed.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'feed_api.g.dart';

@RestApi(baseUrl: "")
abstract class FeedApi {
  factory FeedApi(Dio dio, {String baseUrl}) = _FeedApi;

  @POST("/v1/follows/")
  Future postFollows(
    @Body() Map<String, Object> body,
  );

  @DELETE("/v1/follows/")
  Future deleteFollows(
    @Body() Map<String, Object> body,
  );

  @GET("/v1/follows")
  Future<FollowingData> getFollows(
    @Query("count") int? count,
    @Query("serial") String? serial,
    @Query("timestamp") String? timestamp,
  );

  @GET("/v1/feed")
  Future<FeedData> getFeeds(
    @Query('testnet') bool isTestnet,
    @Query('count') int? count,
    @Query('serial') String? serial,
    @Query('timestamp') String? timestamp,
  );
}
