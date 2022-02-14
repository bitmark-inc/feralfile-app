import 'package:autonomy_flutter/common/app_config.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/gateway/bitmark_api.dart';
import 'package:autonomy_flutter/gateway/feralfile_api.dart';
import 'package:autonomy_flutter/gateway/indexer_api.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:tezart/tezart.dart';
import 'package:web3dart/web3dart.dart';

import 'injector.dart';

class NetworkConfigInjector {
  final testnetInjector = GetIt.asNewInstance();
  final mainnetInjector = GetIt.asNewInstance();

  final ConfigurationService _configurationService;
  final Dio _dio;

  NetworkConfigInjector(this._configurationService, this._dio,
      AppDatabase testnetDB, AppDatabase mainnetDB) {
    //Test network
    testnetInjector.registerLazySingleton(
        () => Web3Client(AppConfig.testNetworkConfig.web3RpcUrl, injector()));
    testnetInjector.registerLazySingleton(
        () => TezartClient(AppConfig.testNetworkConfig.tezosNodeClientUrl));
    testnetInjector.registerLazySingleton<FeralFileApi>(() => FeralFileApi(_dio,
        baseUrl: AppConfig.testNetworkConfig.feralFileApiUrl));
    testnetInjector.registerLazySingleton<BitmarkApi>(() =>
        BitmarkApi(_dio, baseUrl: AppConfig.testNetworkConfig.bitmarkApiUrl));
    testnetInjector.registerLazySingleton<IndexerApi>(() =>
        IndexerApi(_dio, baseUrl: AppConfig.testNetworkConfig.indexerApiUrl));

    testnetInjector.registerLazySingleton<EthereumService>(
        () => EthereumServiceImpl(injector(), testnetInjector()));
    testnetInjector.registerLazySingleton<TezosService>(
        () => TezosServiceImpl(testnetInjector(), injector()));
    testnetInjector.registerLazySingleton<AppDatabase>(() => testnetDB);
    testnetInjector.registerLazySingleton<FeralFileService>(() =>
        FeralFileServiceImpl(
            _configurationService,
            testnetInjector(),
            testnetInjector(),
            testnetInjector(),
            testnetInjector(),
            testnetInjector(),
            testnetInjector()));

    //Main network
    mainnetInjector.registerLazySingleton(
        () => Web3Client(AppConfig.mainNetworkConfig.web3RpcUrl, injector()));
    mainnetInjector.registerLazySingleton(
        () => TezartClient(AppConfig.mainNetworkConfig.tezosNodeClientUrl));
    mainnetInjector.registerLazySingleton<FeralFileApi>(() => FeralFileApi(_dio,
        baseUrl: AppConfig.mainNetworkConfig.feralFileApiUrl));
    mainnetInjector.registerLazySingleton<BitmarkApi>(() =>
        BitmarkApi(_dio, baseUrl: AppConfig.mainNetworkConfig.bitmarkApiUrl));
    mainnetInjector.registerLazySingleton<IndexerApi>(() =>
        IndexerApi(_dio, baseUrl: AppConfig.mainNetworkConfig.indexerApiUrl));

    mainnetInjector.registerLazySingleton<EthereumService>(
        () => EthereumServiceImpl(injector(), mainnetInjector()));
    mainnetInjector.registerLazySingleton<TezosService>(
        () => TezosServiceImpl(mainnetInjector(), injector()));
    mainnetInjector.registerLazySingleton<AppDatabase>(() => mainnetDB);
    mainnetInjector.registerLazySingleton<FeralFileService>(() =>
        FeralFileServiceImpl(
            _configurationService,
            mainnetInjector(),
            mainnetInjector(),
            mainnetInjector(),
            mainnetInjector(),
            mainnetInjector(),
            mainnetInjector()));
  }

  GetIt get I => _configurationService.getNetwork() == Network.MAINNET
      ? mainnetInjector
      : testnetInjector;
}
