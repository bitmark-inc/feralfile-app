//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:math';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/gateway/activation_api.dart';
import 'package:autonomy_flutter/gateway/airdrop_api.dart';
import 'package:autonomy_flutter/gateway/announcement_api.dart';
import 'package:autonomy_flutter/gateway/autonomy_api.dart';
import 'package:autonomy_flutter/gateway/branch_api.dart';
import 'package:autonomy_flutter/gateway/chat_api.dart';
import 'package:autonomy_flutter/gateway/crowd_sourcing_api.dart';
import 'package:autonomy_flutter/gateway/currency_exchange_api.dart';
import 'package:autonomy_flutter/gateway/customer_support_api.dart';
import 'package:autonomy_flutter/gateway/etherchain_api.dart';
import 'package:autonomy_flutter/gateway/feed_api.dart';
import 'package:autonomy_flutter/gateway/feralfile_api.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/gateway/postcard_api.dart';
import 'package:autonomy_flutter/gateway/pubdoc_api.dart';
import 'package:autonomy_flutter/gateway/rendering_report_api.dart';
import 'package:autonomy_flutter/gateway/tzkt_api.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/claim_empty_postcard/claim_empty_postcard_bloc.dart';
import 'package:autonomy_flutter/screen/playlists/add_new_playlist/add_new_playlist_bloc.dart';
import 'package:autonomy_flutter/screen/playlists/edit_playlist/edit_playlist_bloc.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/activation_service.dart';
import 'package:autonomy_flutter/service/airdrop_service.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/autonomy_service.dart';
import 'package:autonomy_flutter/service/background_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service.dart';
import 'package:autonomy_flutter/service/chat_auth_service.dart';
import 'package:autonomy_flutter/service/client_token_service.dart';
import 'package:autonomy_flutter/service/cloud_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/currency_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/deeplink_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/feed_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/followee_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/mix_panel_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/notification_service.dart';
import 'package:autonomy_flutter/service/pending_token_service.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/au_file_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/dio_interceptors.dart';
import 'package:autonomy_flutter/util/dio_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:nft_collection/data/api/indexer_api.dart';
import 'package:nft_collection/graphql/clients/indexer_client.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:nft_collection/services/indexer_service.dart';
import 'package:nft_collection/services/tokens_service.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tezart/tezart.dart';
import 'package:web3dart/web3dart.dart';

final injector = GetIt.instance;
final testnetInjector = GetIt.asNewInstance();

Future<void> setup() async {
  await FileLogger.initializeLogging();

  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    FileLogger.log(record);
    SentryBreadcrumbLogger.log(record);
  });

  final sharedPreferences = await SharedPreferences.getInstance();

  final mainnetDB =
      await $FloorAppDatabase.databaseBuilder('app_database.db').addMigrations([
    migrateV1ToV2,
    migrateV2ToV3,
    migrateV3ToV4,
    migrateV4ToV5,
    migrateV5ToV6,
    migrateV6ToV7,
    migrateV7ToV8,
    migrateV8ToV9,
    migrateV9ToV10,
    migrateV10ToV11,
    migrateV11ToV12,
    migrateV12ToV13,
    migrateV13ToV14,
    migrateV14ToV15,
    migrateV15ToV16,
    migrateV16ToV17
  ]).build();

  final cloudDB = await $FloorCloudDatabase
      .databaseBuilder('cloud_database.db')
      .addMigrations([
    migrateCloudV1ToV2,
    migrateCloudV2ToV3,
    migrateCloudV3ToV4,
    migrateCloudV4ToV5,
    migrateCloudV5ToV6,
    migrateCloudV6ToV7,
    migrateCloudV7ToV8,
  ]).build();

  final BaseOptions dioOptions = BaseOptions(
    followRedirects: true,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
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
  injector.registerLazySingleton(() => cloudDB);

  final authenticatedDio = Dio(); // Authenticated dio instance for AU servers
  authenticatedDio.interceptors.add(AutonomyAuthInterceptor());
  authenticatedDio.interceptors.add(LoggingInterceptor());
  (authenticatedDio.transformer as SyncTransformer).jsonDecodeCallback =
      parseJson;
  dio.interceptors.add(RetryInterceptor(
    dio: dio,
    logPrint: (message) {
      log.warning("[request retry] $message");
    },
    retryDelays: const [
      // set delays between retries
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 3),
    ],
  ));
  authenticatedDio.addSentry();
  authenticatedDio.options = dioOptions;

  // Services
  final auditService = AuditServiceImpl(cloudDB);

  injector.registerSingleton<ConfigurationService>(
      ConfigurationServiceImpl(sharedPreferences));

  injector.registerLazySingleton(() => Client());
  injector.registerLazySingleton(() => NavigationService());
  injector.registerLazySingleton<AutonomyService>(
      () => AutonomyServiceImpl(injector(), injector()));
  injector
      .registerLazySingleton<MetricClientService>(() => MetricClientService());
  injector.registerLazySingleton<MixPanelClientService>(
      () => MixPanelClientService(injector(), injector(), injector()));
  injector.registerLazySingleton<CacheManager>(() => AUImageCacheManage());
  injector.registerLazySingleton<AccountService>(() => AccountServiceImpl(
        cloudDB,
        injector(),
        injector(),
        auditService,
        injector(),
        injector(),
        injector(),
        injector(),
      ));

  injector.registerLazySingleton(() => ChatApi(dio,
      baseUrl: Environment.postcardChatServerUrl.replaceFirst("ws", "http")));
  injector.registerLazySingleton(() => ChatAuthService(injector()));
  injector.registerLazySingleton(
      () => IAPApi(authenticatedDio, baseUrl: Environment.autonomyAuthURL));
  injector.registerLazySingleton(() =>
      AutonomyApi(authenticatedDio, baseUrl: Environment.autonomyAuthURL));

  final tzktUrl = Environment.appTestnetConfig
      ? Environment.tzktTestnetURL
      : Environment.tzktMainnetURL;
  injector.registerLazySingleton(() => TZKTApi(dio, baseUrl: tzktUrl));
  injector.registerLazySingleton(() => EtherchainApi(dio));
  injector.registerLazySingleton(() => BranchApi(dio));
  injector.registerLazySingleton(
      () => PubdocAPI(dio, baseUrl: Environment.pubdocURL));
  injector.registerLazySingleton(
      () => FeedApi(authenticatedDio, baseUrl: Environment.feedURL));
  injector.registerLazySingleton(
      () => AuthService(injector(), injector(), injector(), injector()));
  injector.registerLazySingleton(() => BackupService(injector()));
  injector.registerLazySingleton(() =>
      CrowdSourcingApi(authenticatedDio, baseUrl: Environment.indexerURL));

  injector.registerLazySingleton(
      () => BackgroundService(injector(), injector(), injector()));
  injector
      .registerLazySingleton(() => TezosBeaconService(injector(), injector()));

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
            injector(),
            injector(),
          ));
  injector.registerLazySingleton<IAPService>(
      () => IAPServiceImpl(injector(), injector()));

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
            mainnetDB.draftCustomerSupportDao,
            CustomerSupportApi(authenticatedDio,
                baseUrl: Environment.customerSupportURL),
            RenderingReportApi(authenticatedDio,
                baseUrl: Environment.renderingReportURL),
            injector(),
            injector(),
            mainnetDB.announcementDao,
            AnnouncementApi(authenticatedDio,
                baseUrl: Environment.customerSupportURL),
          ));

  injector.registerLazySingleton<AuditService>(() => auditService);

  final cloudService = CloudService();
  injector.registerLazySingleton(() => cloudService);

  injector.registerLazySingleton(
      () => Web3Client(Environment.web3RpcURL, injector()));

  injector.registerLazySingleton<ClientTokenService>(
      () => ClientTokenService(injector(), injector(), injector(), injector()));

  injector.registerLazySingleton(() => FolloweeService(injector(), injector()));
  final tezosNodeClientURL = Environment.appTestnetConfig
      ? Environment.tezosNodeClientTestnetURL
      : publicTezosNodes[Random().nextInt(publicTezosNodes.length)];
  injector.registerLazySingleton(() => TezartClient(tezosNodeClientURL));
  injector.registerLazySingleton<FeralFileApi>(() => FeralFileApi(
      feralFileDio(dioOptions),
      baseUrl: Environment.feralFileAPIURL));
  injector.registerLazySingleton<IndexerApi>(
      () => IndexerApi(dio, baseUrl: Environment.indexerURL));

  injector.registerLazySingleton<PostcardApi>(() => PostcardApi(
      postcardDio(dioOptions.copyWith(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30))),
      baseUrl: Environment.auClaimAPIURL));

  final indexerClient = IndexerClient(Environment.indexerURL);
  injector.registerLazySingleton<IndexerService>(
      () => IndexerService(indexerClient));

  injector.registerLazySingleton<EthereumService>(
      () => EthereumServiceImpl(injector(), injector()));
  injector
      .registerLazySingleton<TezosService>(() => TezosServiceImpl(injector()));
  injector.registerLazySingleton<AppDatabase>(() => mainnetDB);

  injector
      .registerLazySingleton<FeedService>(() => FeedServiceImpl(injector()));
  injector.registerLazySingleton<PlaylistService>(
      () => PlayListServiceImp(injector(), injector(), injector()));

  injector.registerLazySingleton<CanvasClientService>(
      () => CanvasClientService(injector()));

  injector.registerLazySingleton<PostcardService>(() => PostcardServiceImpl(
      injector(), injector(), injector(), injector(), injector(), injector()));

  injector.registerLazySingleton<AirdropService>(
    () => AirdropService(
      injector(),
      injector(),
      injector(),
      injector(),
      injector(),
      injector(),
      injector(),
      injector(),
    ),
  );

  injector.registerLazySingleton<ActivationService>(() => ActivationService(
        injector(),
        injector(),
        injector(),
      ));

  injector
      .registerLazySingleton<NotificationService>(() => NotificationService());

  injector.registerLazySingleton<AirdropApi>(() => AirdropApi(
      airdropDio(dioOptions.copyWith(followRedirects: true)),
      baseUrl: Environment.autonomyAirdropURL));

  injector.registerLazySingleton<ActivationApi>(() => ActivationApi(
      airdropDio(dioOptions.copyWith(followRedirects: true)),
      baseUrl: Environment.autonomyActivationURL));

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
}
