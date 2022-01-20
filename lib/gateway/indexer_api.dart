import 'package:autonomy_flutter/model/asset.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'indexer_api.g.dart';

@RestApi(baseUrl: "https://nft-indexer.test.bitmark.com/")
abstract class IndexerApi {
  factory IndexerApi(Dio dio, {String baseUrl}) = _IndexerApi;

  @POST("/nft/query")
  Future<List<Asset>> getNftTokens(@Body() Map<String, List<String>> ids);

  @GET("/nft")
  Future<List<Asset>> getNftTokensByOwner(@Query("owner") String owner);

  @POST("/nft/index")
  Future requestIndex(@Body() Map<String, String> payload);
}
