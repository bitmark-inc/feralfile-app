import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/remote_config_api.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/nft_collection/data/api/indexer_api.dart';
import 'package:autonomy_flutter/nft_collection/graphql/clients/indexer_client.dart';
import 'package:autonomy_flutter/nft_collection/services/indexer_service.dart';
import 'package:autonomy_flutter/nft_collection/services/tokens_service.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_bloc.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/util/au_file_service.dart';
import 'package:autonomy_flutter/util/dio_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgetbook_workspace/mock/mock_accounts_bloc.dart';
import 'package:widgetbook_workspace/mock/mock_address_service.dart';
import 'package:widgetbook_workspace/mock/mock_canvas_client_service.dart';
import 'package:widgetbook_workspace/mock/mock_cloud_manager.dart';
import 'package:widgetbook_workspace/mock/mock_feralfile_service.dart';
import 'package:widgetbook_workspace/mock/mock_iap_service.dart';
import 'package:widgetbook_workspace/mock/mock_indexer_api.dart';
import 'package:widgetbook_workspace/mock/mock_indexer_client.dart';
import 'package:widgetbook_workspace/mock/mock_indexer_service.dart';
import 'package:widgetbook_workspace/mock/mock_token_service.dart';

class MockInjector {
  static void setup() async {
    final sharedPreferences = await SharedPreferences.getInstance();

    // iap service
    if (!injector.isRegistered<IAPService>()) {
      injector.registerLazySingleton<IAPService>(() => MockIAPService());
    }

    if (!injector.isRegistered<AddressService>()) {
      injector
          .registerLazySingleton<AddressService>(() => MockAddressService());
    }
    if (!injector.isRegistered<CloudManager>()) {
      injector.registerLazySingleton<CloudManager>(() => MockCloudManager());
    }
    if (!injector.isRegistered<CanvasClientServiceV2>()) {
      injector.registerLazySingleton<CanvasClientServiceV2>(
          () => MockCanvasClientServiceV2());
    }

    // feralfile service
    if (!injector.isRegistered<FeralFileService>()) {
      injector.registerLazySingleton<FeralFileService>(
          () => MockFeralfileService());
    }

    if (!injector.isRegistered<CanvasDeviceBloc>()) {
      injector.registerLazySingleton<CanvasDeviceBloc>(
          () => CanvasDeviceBloc(injector.get()));
    }

    // indexer service
    if (!injector.isRegistered<IndexerClient>()) {
      injector.registerLazySingleton<IndexerClient>(() => MockIndexerClient());
    }
    if (!injector.isRegistered<IndexerApi>()) {
      injector.registerLazySingleton<IndexerApi>(() => MockIndexerApi());
    }
    if (!injector.isRegistered<IndexerService>()) {
      injector.registerLazySingleton<IndexerService>(
          () => MockIndexerService(injector.get(), injector.get()));
    }

    // token service
    if (!injector.isRegistered<TokensService>()) {
      injector.registerLazySingleton<TokensService>(() => MockTokensService());
    }

    // coòniguration service
    if (!injector.isRegistered<ConfigurationService>()) {
      injector.registerLazySingleton<ConfigurationService>(
          () => ConfigurationServiceImpl(sharedPreferences));
    }

    if (!injector.isRegistered<RemoteConfigService>()) {
      injector.registerLazySingleton<RemoteConfigService>(() =>
          RemoteConfigServiceImpl(RemoteConfigApi(baseDio(BaseOptions()))));
    }

    if (!injector.isRegistered<CacheManager>()) {
      injector.registerLazySingleton<CacheManager>(AUImageCacheManage.new);
    }

    // daily bloc
    if (!injector.isRegistered<DailyWorkBloc>()) {
      injector.registerLazySingleton<DailyWorkBloc>(
        () => DailyWorkBloc(injector.get(), injector.get()),
      );
    }

    // account bloc
    if (!injector.isRegistered<AccountsBloc>()) {
      injector.registerLazySingleton<AccountsBloc>(
        () => MockAccountsBloc(),
      );
    }

    // upgrade bloc
    if (!injector.isRegistered<UpgradesBloc>()) {
      injector.registerLazySingleton<UpgradesBloc>(
        () => UpgradesBloc(injector.get(), injector.get()),
      );
    }

    // subscription bloc
    if (!injector.isRegistered<SubscriptionBloc>()) {
      injector.registerLazySingleton<SubscriptionBloc>(
        () => SubscriptionBloc(injector.get()),
      );
    }

    final identityStore = IndexerIdentityStore();
    // identity bloc
    if (!injector.isRegistered<IdentityBloc>()) {
      injector.registerLazySingleton<IdentityBloc>(
        () => IdentityBloc(identityStore, injector.get()),
      );
    }
  }

  static T get<T extends Object>() {
    return injector.get<T>();
  }
}
