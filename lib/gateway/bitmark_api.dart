import 'package:autonomy_flutter/model/bitmark.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'bitmark_api.g.dart';

@RestApi(baseUrl: "")
abstract class BitmarkApi {
  factory BitmarkApi(Dio dio, {String baseUrl}) = _BitmarkApi;

  @GET("/v1/bitmarks")
  Future<Map<String, List<Bitmark>>> getBitmarkIDs(
    @Query("owner") String owner,
    @Query("pending") bool includePending,
  );
}
