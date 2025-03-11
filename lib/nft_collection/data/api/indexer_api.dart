//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:dio/dio.dart';
import 'package:autonomy_flutter/nft_collection/models/asset_token.dart';
import 'package:autonomy_flutter/nft_collection/models/user_collection.dart';
import 'package:retrofit/retrofit.dart';

part 'indexer_api.g.dart';

@RestApi(baseUrl: "")
abstract class IndexerApi {
  factory IndexerApi(Dio dio, {String baseUrl}) = _IndexerApi;

  @POST("/v2/nft/query")
  Future<List<AssetToken>> getNFTTokens(
    @Query("offset") int offset,
  );

  @POST("/v2/nft/index")
  Future<void> requestIndex(@Body() Map<String, dynamic> payload);

  @POST("/v2/nft/index_history")
  Future<void> indexTokenHistory(
    @Body() Map<String, dynamic> payload,
  );

  @GET("/v2/nft/count")
  Future numberNft(
    @Query("owner") String owner,
  );

  @GET("/v2/collections")
  Future<List<UserCollection>> getCollection(
    @Query("creators") String creator,
    @Query("size") int size,
  );
}
