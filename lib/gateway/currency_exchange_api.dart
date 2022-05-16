import 'package:autonomy_flutter/model/currency_exchange.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'currency_exchange_api.g.dart';

@RestApi(baseUrl: "")
abstract class CurrencyExchangeApi {
  factory CurrencyExchangeApi(Dio dio, {String baseUrl}) = _CurrencyExchangeApi;

  @GET("/v2/exchange-rates")
  Future<Map<String, CurrencyExchange>> getExchangeRates();
}
