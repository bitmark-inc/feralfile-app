import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'merchandise_api.g.dart';

@RestApi(baseUrl: '')
abstract class MerchandiseApi {
  factory MerchandiseApi(Dio dio, {String baseUrl}) = _MerchandiseApi;

  @GET('/v1/products')
  Future<dynamic> getProducts(@Query('index_id') String indexId);
}
