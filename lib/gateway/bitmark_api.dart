import 'package:autonomy_flutter/model/bitmark.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'bitmark_api.g.dart';

@RestApi(baseUrl: "https://api.test.bitmark.com/")
abstract class BitmarkApi {
  factory BitmarkApi(Dio dio, {String baseUrl}) = _BitmarkApi;

  @GET("/v1/bitmarks")
  Future<Map<String, List<Bitmark>>> getBitmarkIDs(
    @Query("owner") String owner,
    @Query("pending") bool includePending,
  );

  @GET("/v1/bitmarks/{id}")
  Future<Map<String, Bitmark>> getBitmarkAssetInfo(
    @Path("id") String id,
    @Query("pending") bool includePending,
    @Query("provenance") bool provenance,
  );
}
