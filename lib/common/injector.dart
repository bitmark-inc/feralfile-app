import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/persona_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';

final injector = GetIt.instance;

Future<void> setup() async {
  final sharedPreferences = await SharedPreferences.getInstance();

  injector.registerSingleton<ConfigurationService>(ConfigurationServiceImpl(sharedPreferences));
  injector.registerSingleton(Client());
  injector.registerSingleton(() => NavigationService());
  injector.registerSingleton(() => WalletConnectService(injector()));

  injector.registerLazySingleton(() => Web3Client("https://rinkeby.infura.io/v3/20aba74f4e8642b88808ff4df18c10ff", injector()));
  injector.registerLazySingleton<PersonaService>(() => PersonaServiceImpl(injector()));
  injector.registerLazySingleton<EthereumService>(() => EthereumServiceImpl(injector(), injector()));
}