//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: cascade_invocations

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/gateway/branch_api.dart';
import 'package:autonomy_flutter/gateway/chat_api.dart';
import 'package:autonomy_flutter/gateway/currency_exchange_api.dart';
import 'package:autonomy_flutter/gateway/customer_support_api.dart';
import 'package:autonomy_flutter/gateway/etherchain_api.dart';
import 'package:autonomy_flutter/gateway/feralfile_api.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/gateway/merchandise_api.dart';
import 'package:autonomy_flutter/gateway/postcard_api.dart';
import 'package:autonomy_flutter/gateway/pubdoc_api.dart';
import 'package:autonomy_flutter/gateway/remote_config_api.dart';
import 'package:autonomy_flutter/gateway/source_exhibition_api.dart';
import 'package:autonomy_flutter/gateway/tv_cast_api.dart';
import 'package:autonomy_flutter/gateway/user_api.dart';
import 'package:autonomy_flutter/graphql/account_settings/account_settings_client.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/screen/bloc/connections/connections_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_bloc.dart';
import 'package:autonomy_flutter/screen/chat/chat_bloc.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_bloc.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/home/list_playlist_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/claim_empty_postcard/claim_empty_postcard_bloc.dart';
import 'package:autonomy_flutter/screen/playlists/add_new_playlist/add_new_playlist_bloc.dart';
import 'package:autonomy_flutter/screen/playlists/edit_playlist/edit_playlist_bloc.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist_bloc.dart';
import 'package:autonomy_flutter/screen/predefined_collection/predefined_collection_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/announcement/announcement_service.dart';
import 'package:autonomy_flutter/service/announcement/announcement_store.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/chat_auth_service.dart';
import 'package:autonomy_flutter/service/chat_service.dart';
import 'package:autonomy_flutter/service/client_token_service.dart';
import 'package:autonomy_flutter/service/cloud_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/currency_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/deeplink_service.dart';
import 'package:autonomy_flutter/service/device_info_service.dart';
import 'package:autonomy_flutter/service/domain_address_service.dart';
import 'package:autonomy_flutter/service/domain_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/hive_service.dart';
import 'package:autonomy_flutter/service/hive_store_service.dart';
import 'package:autonomy_flutter/service/home_widget_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/keychain_service.dart';
import 'package:autonomy_flutter/service/merchandise_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/network_issue_manager.dart';
import 'package:autonomy_flutter/service/network_service.dart';
import 'package:autonomy_flutter/service/passkey_service.dart';
import 'package:autonomy_flutter/service/pending_token_service.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/user_interactivity_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/au_file_service.dart';
import 'package:autonomy_flutter/util/dio_interceptors.dart';
import 'package:autonomy_flutter/util/dio_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/user_account_channel.dart';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:nft_collection/data/api/indexer_api.dart';
import 'package:nft_collection/data/api/tzkt_api.dart';
import 'package:nft_collection/graphql/clients/indexer_client.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:nft_collection/services/indexer_service.dart';
import 'package:nft_collection/services/tokens_service.dart';
import 'package:sentry/sentry.dart';
import 'package:shared_preferences/shared_preferences.dart';

final injector = GetIt.instance;
final testnetInjector = GetIt.asNewInstance();

const iapApiTimeout5secInstanceName = 'iapApiTimeout5sec';

Future<void> setupLogger() async {
  await FileLogger.initializeLogging();

  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    try {
      FileLogger.log(record);
      SentryBreadcrumbLogger.log(record);
    } catch (e, s) {
      Sentry.captureException('Error logging record: $e', stackTrace: s);
    }
  });
}

Future<void> setupHomeWidgetInjector() async {
  final BaseOptions dioOptions = BaseOptions(
    followRedirects: true,
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
  );
  final dio = baseDio(dioOptions);
  injector.registerLazySingleton<FeralFileApi>(() => FeralFileApi(
      feralFileDio(dioOptions),
      baseUrl: Environment.feralFileAPIURL));
  injector.registerLazySingleton(
      () => SourceExhibitionAPI(dio, baseUrl: Environment.pubdocURL));
  injector.registerLazySingleton<FeralFileService>(() => FeralFileServiceImpl(
        injector(),
        injector(),
      ));
  final indexerClient = IndexerClient(Environment.indexerURL);
  injector.registerLazySingleton<IndexerService>(
      () => IndexerService(indexerClient));
  injector.registerLazySingleton<RemoteConfigService>(() =>
      RemoteConfigServiceImpl(
          RemoteConfigApi(dio, baseUrl: Environment.remoteConfigURL)));
}

Future<void> setupInjector() async {
  final sharedPreferences = await SharedPreferences.getInstance();

  injector.registerLazySingleton(() => NavigationService());

  injector
      .registerLazySingleton<NetworkIssueManager>(() => NetworkIssueManager());

  final BaseOptions dioOptions = BaseOptions(
    followRedirects: true,
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
  );
  final dio = baseDio(dioOptions);

  final pendingTokenExpireMs = Environment.pendingTokenExpireMs;
  await NftCollection.initNftCollection(
      indexerUrl: Environment.indexerURL,
      logger: log,
      apiLogger: apiLog,
      dio: dio);
  injector
      .registerLazySingleton<TokensService>(() => NftCollection.tokenService);
  injector.registerLazySingleton(() => NftCollection.prefs);
  injector.registerLazySingleton(() => NftCollection.database);
  injector.registerLazySingleton(() => NftCollection.addressService);
  injector.registerLazySingleton(() => NftCollection.database.assetDao);
  injector.registerLazySingleton(() => NftCollection.database.tokenDao);
  injector.registerLazySingleton(() => NftCollection.database.assetTokenDao);
  injector.registerLazySingleton(() => NftCollection.database.provenanceDao);
  injector.registerLazySingleton(
      () => NftCollection.database.predefinedCollectionDao);

  final authenticatedDio =
      baseDio(dioOptions); // Authenticated dio instance for AU servers
  authenticatedDio.interceptors.add(AutonomyAuthInterceptor());
  authenticatedDio.interceptors.add(MetricsInterceptor());

  injector.registerLazySingleton<NetworkService>(() => NetworkService());
  // Services

  injector.registerSingleton<ConfigurationService>(
      ConfigurationServiceImpl(sharedPreferences));
  injector.registerLazySingleton(() => http.Client());
  injector
      .registerLazySingleton<MetricClientService>(() => MetricClientService());
  injector.registerLazySingleton<CacheManager>(() => AUImageCacheManage());
  injector.registerLazySingleton<AccountService>(() => AccountServiceImpl(
        injector(),
        injector(),
        injector(),
        injector(),
        injector(),
      ));

  injector
      .registerLazySingleton<UserAccountChannel>(() => UserAccountChannel());

  injector.registerLazySingleton<AddressService>(
      () => AddressService(injector(), injector()));

  injector.registerLazySingleton<KeychainService>(() => KeychainService());

  injector.registerLazySingleton(() => ChatApi(chatDio(dioOptions),
      baseUrl: Environment.postcardChatServerUrl.replaceFirst('ws', 'http')));
  injector.registerLazySingleton(() => ChatAuthService(injector()));
  injector.registerLazySingleton(
      () => IAPApi(authenticatedDio, baseUrl: Environment.autonomyAuthURL));

  injector.registerLazySingleton(
      () => IAPApi(dio, baseUrl: Environment.autonomyAuthURL),
      instanceName: iapApiTimeout5secInstanceName);

  injector.registerLazySingleton(
      () => UserApi(dio, baseUrl: Environment.autonomyAuthURL));

  injector.registerLazySingleton<UserInteractivityService>(
      () => UserInteractivityServiceImpl(injector(), injector()));

  final tzktUrl = Environment.appTestnetConfig
      ? Environment.tzktTestnetURL
      : Environment.tzktMainnetURL;
  injector.registerLazySingleton(() => TZKTApi(dio, baseUrl: tzktUrl));
  injector.registerLazySingleton(() => EtherchainApi(dio));
  injector.registerLazySingleton(() => BranchApi(dio));
  injector.registerLazySingleton(
      () => PubdocAPI(dio, baseUrl: Environment.pubdocURL));
  injector.registerLazySingleton(
      () => SourceExhibitionAPI(dio, baseUrl: Environment.pubdocURL));
  injector.registerLazySingleton<RemoteConfigService>(() =>
      RemoteConfigServiceImpl(
          RemoteConfigApi(dio, baseUrl: Environment.remoteConfigURL)));
  injector.registerLazySingleton(
      () => AuthService(injector(), injector(), injector()));
  injector
      .registerLazySingleton(() => TezosBeaconService(injector(), injector()));

  injector.registerLazySingleton<PasskeyService>(() => PasskeyServiceImpl(
        injector(),
        injector(),
        injector(),
        injector(),
      ));

  injector.registerFactoryParam<NftCollectionBloc, bool?, dynamic>(
      (p1, p2) => NftCollectionBloc(
            injector(),
            injector(),
            injector(),
            injector(),
            pendingTokenExpire: pendingTokenExpireMs != null
                ? Duration(milliseconds: pendingTokenExpireMs)
                : const Duration(hours: 4),
            isSortedToken: p1 ?? true,
          ));

  injector
      .registerLazySingleton<SettingsDataService>(() => SettingsDataServiceImpl(
            injector(),
            injector(),
          ));

  injector.registerLazySingleton<IAPService>(
      () => IAPServiceImpl(injector(), injector()));

  injector.registerLazySingleton(() => TvCastApi(
      tvCastDio(
        dioOptions.copyWith(
          receiveTimeout: const Duration(seconds: 10),
          connectTimeout: const Duration(seconds: 10),
        ),
      ),
      baseUrl: Environment.tvCastApiUrl));
  injector.registerLazySingleton(() => Wc2Service(
        injector(),
        injector(),
        injector(),
      ));
  injector.registerLazySingleton<CurrencyExchangeApi>(
      () => CurrencyExchangeApi(dio, baseUrl: Environment.currencyExchangeURL));
  injector.registerLazySingleton<CurrencyService>(
      () => CurrencyServiceImpl(injector()));
  injector.registerLazySingleton(
      () => VersionService(injector(), injector(), injector()));

  injector.registerLazySingleton<CustomerSupportService>(
      () => CustomerSupportServiceImpl(
            CustomerSupportApi(
                customerSupportDio(
                  dioOptions.copyWith(
                    connectTimeout: const Duration(seconds: 10),
                    receiveTimeout: const Duration(seconds: 10),
                  ),
                ),
                baseUrl: Environment.customerSupportURL),
            injector(),
          ));

  injector.registerLazySingleton<MerchandiseService>(
      () => MerchandiseServiceImpl(MerchandiseApi(
            authenticatedDio,
            baseUrl: Environment.merchandiseApiUrl,
          )));

  final cloudService = CloudService();
  injector.registerLazySingleton(() => cloudService);

  injector.registerLazySingleton<DomainService>(() => DomainServiceImpl());

  injector.registerLazySingleton<DomainAddressService>(
      () => DomainAddressServiceImpl(injector()));

  injector.registerLazySingleton<ClientTokenService>(
      () => ClientTokenService(injector(), injector(), injector(), injector()));
  injector.registerLazySingleton<FeralFileApi>(() => FeralFileApi(
      feralFileDio(dioOptions),
      baseUrl: Environment.feralFileAPIURL));
  injector.registerLazySingleton<IndexerApi>(
      () => IndexerApi(dio, baseUrl: Environment.indexerURL));

  final indexerClient = IndexerClient(Environment.indexerURL);
  injector.registerLazySingleton<IndexerService>(
      () => IndexerService(indexerClient));

  injector.registerLazySingleton<EthereumService>(() =>
      EthereumServiceImpl(injector(), injector(), injector(), injector()));
  injector.registerLazySingleton<HiveService>(() => HiveServiceImpl());
  injector.registerLazySingleton<PlaylistService>(() => PlayListServiceImp(
      injector(), injector(), injector(), injector(), injector()));
  injector.registerLazySingleton<DeviceInfoService>(() => DeviceInfoService());

  injector.registerLazySingleton<HiveStoreObjectService<CanvasDevice>>(
      () => HiveStoreObjectServiceImpl());
  await injector<HiveStoreObjectService<CanvasDevice>>()
      .init('local.canvas_device');
  injector.registerLazySingleton<CanvasClientServiceV2>(() =>
      CanvasClientServiceV2(injector(), injector(), injector(), injector()));

  injector.registerLazySingleton<PostcardService>(
    () => PostcardServiceImpl(
      injector(),
      injector(),
      injector(),
      injector(),
      injector(),
      injector(),
      injector(),
    ),
  );

  injector.registerLazySingleton<ChatService>(() => ChatServiceImpl(
        injector(),
        injector(),
      ));

  injector.registerLazySingleton<FeralFileService>(() => FeralFileServiceImpl(
        injector(),
        injector(),
      ));

  injector.registerLazySingleton<DeeplinkService>(() => DeeplinkServiceImpl(
        injector(),
        injector(),
        injector(),
        injector(),
        injector(),
        injector(),
        injector(),
      ));

  injector.registerLazySingleton<PendingTokenService>(() => PendingTokenService(
        injector(),
        injector(),
        injector(),
        NftCollection.database.assetTokenDao,
        NftCollection.database.tokenDao,
        NftCollection.database.assetDao,
      ));
  injector.registerFactory<AddNewPlaylistBloc>(
      () => AddNewPlaylistBloc(injector()));
  injector
      .registerFactory<ViewPlaylistBloc>(() => ViewPlaylistBloc(injector()));
  injector.registerFactory<EditPlaylistBloc>(() => EditPlaylistBloc());
  injector
      .registerFactory<ClaimEmptyPostCardBloc>(() => ClaimEmptyPostCardBloc());
  injector.registerFactory<CollectionProBloc>(() => CollectionProBloc());
  injector.registerFactory<PredefinedCollectionBloc>(
      () => PredefinedCollectionBloc());
  injector.registerFactory<IdentityBloc>(
      () => IdentityBloc(injector(), injector()));
  injector.registerFactory<AuChatBloc>(() => AuChatBloc(injector()));

  injector.registerLazySingleton<ConnectionsBloc>(() => ConnectionsBloc(
        injector(),
        injector(),
        injector(),
      ));
  injector.registerLazySingleton<CanvasDeviceBloc>(
      () => CanvasDeviceBloc(injector()));
  injector.registerLazySingleton<SubscriptionBloc>(
      () => SubscriptionBloc(injector()));
  injector.registerLazySingleton<DailyWorkBloc>(
      () => DailyWorkBloc(injector(), injector()));

  injector.registerLazySingleton<AnnouncementStore>(() => AnnouncementStore());
  await injector<AnnouncementStore>().init('');

  injector.registerLazySingleton<AnnouncementService>(
      () => AnnouncementServiceImpl(injector(), injector(), injector()));

  injector.registerLazySingleton<UpgradesBloc>(
      () => UpgradesBloc(injector(), injector()));

  injector.registerLazySingleton<AccountSettingsClient>(
      () => AccountSettingsClient(Environment.accountSettingUrl));

  injector.registerLazySingleton<CloudManager>(() => CloudManager());

  injector.registerLazySingleton<ListPlaylistBloc>(() => ListPlaylistBloc());

  injector.registerLazySingleton<HomeWidgetService>(() => HomeWidgetService());
}
