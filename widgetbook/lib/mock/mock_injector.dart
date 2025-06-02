import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:get_it/get_it.dart';

import 'mock_accounts_bloc.dart';
import 'mock_address_service.dart';
import 'mock_cloud_manager.dart';
import 'mock_nft_address_service.dart' as nft;

class MockInjector {
  static final GetIt _getIt = GetIt.instance;

  static void setup() {
    if (!_getIt.isRegistered<AddressService>()) {
      _getIt.registerLazySingleton<AddressService>(() => MockAddressService());
    }
    if (!_getIt.isRegistered<CloudManager>()) {
      _getIt.registerLazySingleton<CloudManager>(() => MockCloudManager());
    }
    if (!_getIt.isRegistered<AccountsBloc>()) {
      _getIt.registerFactory<AccountsBloc>(() => MockAccountsBloc());
    }
    if (!_getIt.isRegistered<MockAccountsBloc>()) {
      _getIt.registerFactory<MockAccountsBloc>(() => MockAccountsBloc());
    }
  }

  static T get<T extends Object>() => _getIt<T>();
}
