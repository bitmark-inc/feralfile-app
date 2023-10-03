//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/feed.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'feed_api.g.dart';

@RestApi(baseUrl: "")
abstract class FeedApi {
  factory FeedApi(Dio dio, {String baseUrl}) = _FeedApi;

  @POST("/v2/follows/")
  Future postFollows(
    @Body() Map<String, Object> body,
  );

  @DELETE("/v2/follows/")
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
