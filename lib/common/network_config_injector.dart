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
  final Dio _dioHTTP2;

  NetworkConfigInjector(this._configurationService, this._dio, this._dioHTTP2,
      AppDatabase testnetDB, AppDatabase mainnetDB) {
    //Test network
    testnetInjector.registerLazySingleton(
        () => Web3Client(Environment.web3RpcTestnetURL, injector()));
    testnetInjector.registerLazySingleton(
        () => TezartClient(Environment.tezosNodeClientTestnetURL));
    testnetInjector.registerLazySingleton<FeralFileApi>(
        () => FeralFileApi(_dio, baseUrl: Environment.feralFileAPITestnetURL));
    testnetInjector.registerLazySingleton<BitmarkApi>(
        () => BitmarkApi(_dio, baseUrl: Environment.bitmarkAPITestnetURL));
    testnetInjector.registerLazySingleton<IndexerApi>(
        () => IndexerApi(_dioHTTP2, baseUrl: Environment.indexerTestnetURL));

    testnetInjector.registerLazySingleton<EthereumService>(
        () => EthereumServiceImpl(testnetInjector()));
    testnetInjector.registerLazySingleton<TezosService>(
        () => TezosServiceImpl(testnetInjector()));
    testnetInjector.registerLazySingleton<AppDatabase>(() => testnetDB);
    testnetInjector.registerLazySingleton<FeralFileService>(
        () => FeralFileServiceImpl(testnetInjector()));

    //Main network
    mainnetInjector.registerLazySingleton(
        () => Web3Client(Environment.web3RpcMainnetURL, injector()));
    mainnetInjector.registerLazySingleton(
        () => TezartClient(Environment.tezosNodeClientMainnetURL));
    mainnetInjector.registerLazySingleton<FeralFileApi>(
        () => FeralFileApi(_dio, baseUrl: Environment.feralFileAPIMainnetURL));
    mainnetInjector.registerLazySingleton<BitmarkApi>(
        () => BitmarkApi(_dio, baseUrl: Environment.bitmarkAPIMainnetURL));
    mainnetInjector.registerLazySingleton<IndexerApi>(
        () => IndexerApi(_dioHTTP2, baseUrl: Environment.indexerMainnetURL));

    mainnetInjector.registerLazySingleton<EthereumService>(
        () => EthereumServiceImpl(mainnetInjector()));
    mainnetInjector.registerLazySingleton<TezosService>(
        () => TezosServiceImpl(mainnetInjector()));
    mainnetInjector.registerLazySingleton<AppDatabase>(() => mainnetDB);
    mainnetInjector.registerLazySingleton<FeralFileService>(
        () => FeralFileServiceImpl(mainnetInjector()));
  }

  GetIt get I => _configurationService.getNetwork() == Network.MAINNET
      ? mainnetInjector
      : testnetInjector;
}
