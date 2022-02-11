import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/gateway/currency_exchange_api.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/currency_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/persona_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'network_config_injector.dart';

import 'package:logging/logging.dart';
import 'package:autonomy_flutter/util/log.dart';

final injector = GetIt.instance;

Future<void> setup() async {
  await FileLogger.initializeLogging();

  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
    FileLogger.log(record.toString());
  });

  final sharedPreferences = await SharedPreferences.getInstance();

  final testnetDB = await $FloorAppDatabase
      .databaseBuilder('app_database_testnet.db')
      .build();
  final mainnetDB = await $FloorAppDatabase
      .databaseBuilder('app_database_testnet.db')
      .build();

  final dio = Dio(); // Provide a dio instance
  dio.interceptors.add(LoggingInterceptor());

  injector.registerSingleton<ConfigurationService>(
      ConfigurationServiceImpl(sharedPreferences));

  injector.registerLazySingleton(() => Client());
  injector.registerLazySingleton(() => NavigationService());

  injector.registerLazySingleton(
      () => WalletConnectService(injector(), injector()));
  injector
      .registerLazySingleton(() => TezosBeaconService(injector(), injector()));
  injector.registerLazySingleton<CurrencyExchangeApi>(
      () => CurrencyExchangeApi(dio));
  injector.registerLazySingleton<PersonaService>(
      () => PersonaServiceImpl(injector()));
  injector.registerLazySingleton<CurrencyService>(
      () => CurrencyServiceImpl(injector()));

  injector.registerLazySingleton(
      () => NetworkConfigInjector(injector(), dio, testnetDB, mainnetDB));
}
