import 'package:autonomy_flutter/model/merchandise_order.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'merchandise_api.g.dart';

@RestApi(baseUrl: '')
abstract class MerchandiseApi {
  factory MerchandiseApi(Dio dio, {String baseUrl}) = _MerchandiseApi;

  @GET('/v1/orders/{id}')
  Future<MerchandiseOrderResponse> getOrder(
    @Path('id') String id,
  );
}
