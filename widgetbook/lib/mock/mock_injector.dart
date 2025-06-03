import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/nft_collection/data/api/indexer_api.dart';
import 'package:autonomy_flutter/nft_collection/graphql/clients/indexer_client.dart';
import 'package:autonomy_flutter/nft_collection/services/indexer_service.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_bloc.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
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

    // coòniguration service
    if (!injector.isRegistered<ConfigurationService>()) {
      injector.registerLazySingleton<ConfigurationService>(
          () => ConfigurationServiceImpl(sharedPreferences));
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
  }

  static T get<T extends Object>() {
    return injector.get<T>();
  }
}
