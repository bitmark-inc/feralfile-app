import 'package:autonomy_flutter/gateway/bitmark_api.dart';
import 'package:autonomy_flutter/gateway/feralfile_api.dart';
import 'package:autonomy_flutter/gateway/indexer_api.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/persona_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';

final injector = GetIt.instance;

Future<void> setup() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  final dio = Dio(); // Provide a dio instance

  injector.registerSingleton<ConfigurationService>(
      ConfigurationServiceImpl(sharedPreferences));

  injector.registerLazySingleton(() => Client());
  injector.registerLazySingleton(() => Web3Client(
      "https://rinkeby.infura.io/v3/20aba74f4e8642b88808ff4df18c10ff",
      injector()));

  injector.registerLazySingleton(() => NavigationService());
  injector.registerLazySingleton(
      () => WalletConnectService(injector(), injector()));

  injector.registerLazySingleton<FeralFileApi>(() => FeralFileApi(dio));
  injector.registerLazySingleton<BitmarkApi>(() => BitmarkApi(dio));
  injector.registerLazySingleton<IndexerApi>(() => IndexerApi(dio));

  injector.registerLazySingleton<PersonaService>(
      () => PersonaServiceImpl(injector()));
  injector.registerLazySingleton<EthereumService>(
      () => EthereumServiceImpl(injector(), injector()));
  injector.registerLazySingleton<FeralFileService>(() => FeralFileServiceImpl(
      injector(), injector(), injector(), injector(), injector()));
}
