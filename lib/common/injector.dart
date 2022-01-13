import 'package:autonomy_flutter/gateway/currency_exchange_api.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/currency_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/persona_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'network_config_injector.dart';

final injector = GetIt.instance;

Future<void> setup() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  final dio = Dio(); // Provide a dio instance

  injector.registerSingleton<ConfigurationService>(
      ConfigurationServiceImpl(sharedPreferences));

  injector.registerLazySingleton(() => Client());
  injector.registerLazySingleton(() => NavigationService());

  injector.registerLazySingleton(
      () => WalletConnectService(injector(), injector()));
  injector.registerLazySingleton<CurrencyExchangeApi>(
      () => CurrencyExchangeApi(dio));
  injector.registerLazySingleton<PersonaService>(
      () => PersonaServiceImpl(injector()));
  injector.registerLazySingleton<CurrencyService>(
      () => CurrencyServiceImpl(injector()));

  injector.registerLazySingleton(() => NetworkConfigInjector(injector(), dio));
}
