//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/asset.dart';
import 'package:autonomy_flutter/model/identity.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'indexer_api.g.dart';

@RestApi(baseUrl: "")
abstract class IndexerApi {
  factory IndexerApi(Dio dio, {String baseUrl}) = _IndexerApi;

  @POST("/nft/query")
  Future<List<Asset>> getNftTokens(@Body() Map<String, List<String>> ids);

  @POST("/nft/query")
  Future<List<Asset>> getNFTTokens(
    @Query("offset") int offset,
  );

  @GET("/nft")
  Future<List<Asset>> getNftTokensByOwner(
    @Query("owner") String owner,
    @Query("offset") int offset,
    @Query("size") int size,
  );

  @POST("/nft/index")
  Future requestIndex(@Body() Map<String, String> payload);

  @POST("/nft/index_one")
  Future requestIndexOne(@Body() Map<String, dynamic> payload);

  @GET("/identity/{accountNumber}")
  Future<BlockchainIdentity> getIdentity(
    @Path("accountNumber") String accountNumber,
  );

  @GET("/nft/owned")
  Future<List<String>> getNftIDsByOwner(
    @Query("owner") String owner,
  );
}
