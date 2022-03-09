import 'dart:convert';

import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/gateway/currency_exchange_api.dart';
import 'package:autonomy_flutter/service/aws_service.dart';
import 'package:autonomy_flutter/service/cloud_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/currency_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_dapp_service/wallet_connect_dapp_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/dio_interceptors.dart';
import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:flutter/foundation.dart';
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
    FileLogger.log(record);
    SentryBreadcrumbLogger.log(record);
  });

  final sharedPreferences = await SharedPreferences.getInstance();

  final testnetDB = await $FloorAppDatabase
      .databaseBuilder('app_database_testnet.db')
      .build();
  final mainnetDB = await $FloorAppDatabase
      .databaseBuilder('app_database_testnet.db')
      .build();

  final cloudDB =
      await $FloorCloudDatabase.databaseBuilder('cloud_database.db').build();

  injector.registerLazySingleton(() => cloudDB);

  final dio = Dio(); // Provide a dio instance
  dio.interceptors.add(LoggingInterceptor());
  dio.interceptors.add(SentryInterceptor());
  (dio.transformer as DefaultTransformer).jsonDecodeCallback = parseJson;

  final dioHTTP2 = Dio(); // Provide a dio instance
  dioHTTP2.interceptors.add(LoggingInterceptor());
  dioHTTP2.interceptors.add(SentryInterceptor());
  dioHTTP2.httpClientAdapter =
      Http2Adapter(ConnectionManager(idleTimeout: 10000));

  injector.registerSingleton<ConfigurationService>(
      ConfigurationServiceImpl(sharedPreferences));

  injector.registerLazySingleton(() => Client());
  injector.registerLazySingleton(() => NavigationService());
  injector.registerLazySingleton(() => AWSService(injector()));

  injector.registerLazySingleton(
      () => WalletConnectService(injector(), injector()));
  injector.registerLazySingleton(() => WalletConnectDappService(injector()));

  injector
      .registerLazySingleton(() => TezosBeaconService(injector(), injector()));
  injector.registerLazySingleton<CurrencyExchangeApi>(
      () => CurrencyExchangeApi(dio));
  injector.registerLazySingleton<CurrencyService>(
      () => CurrencyServiceImpl(injector()));

  final cloudService = CloudService();
  injector.registerLazySingleton(() => cloudService);

  injector.registerLazySingleton(() =>
      NetworkConfigInjector(injector(), dio, dioHTTP2, testnetDB, mainnetDB));
}

// Must be top-level function
_parseAndDecode(String response) {
  return jsonDecode(response);
}

parseJson(String text) {
  return compute(_parseAndDecode, text);
}