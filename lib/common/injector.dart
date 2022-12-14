//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/gateway/autonomy_api.dart';
import 'package:autonomy_flutter/gateway/bitmark_api.dart';
import 'package:autonomy_flutter/gateway/branch_api.dart';
import 'package:autonomy_flutter/gateway/currency_exchange_api.dart';
import 'package:autonomy_flutter/gateway/customer_support_api.dart';
import 'package:autonomy_flutter/gateway/etherchain_api.dart';
import 'package:autonomy_flutter/gateway/feed_api.dart';
import 'package:autonomy_flutter/gateway/feralfile_api.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/gateway/pubdoc_api.dart';
import 'package:autonomy_flutter/gateway/rendering_report_api.dart';
import 'package:autonomy_flutter/gateway/tzkt_api.dart';
import 'package:autonomy_flutter/screen/add_new_playlist/add_new_playlist_bloc.dart';
import 'package:autonomy_flutter/screen/edit_playlist/edit_playlist_bloc.dart';
import 'package:autonomy_flutter/screen/view_playlist/view_playlist_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/autonomy_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/cloud_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/currency_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/deeplink_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/feed_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/ledger_hardware/ledger_hardware_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/mix_panel_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/pending_token_service.dart';
import 'package:autonomy_flutter/service/play_control_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_dapp_service/wallet_connect_dapp_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/au_file_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/dio_interceptors.dart';
import 'package:autonomy_flutter/util/isolated_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:nft_collection/data/api/indexer_api.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tezart/tezart.dart';
import 'package:web3dart/web3dart.dart';

final injector = GetIt.instance;
final testnetInjector = GetIt.asNewInstance();

Future<void> setup() async {
  FileLogger.initializeLogging();

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
  ]).build();

  final cloudDB = await $FloorCloudDatabase
      .databaseBuilder('cloud_database.db')
      .addMigrations([
    migrateCloudV1ToV2,
    migrateCloudV2ToV3,
  ]).build();

  injector.registerLazySingleton(() => cloudDB);

  final dio = Dio(); // Default a dio instance
  dio.interceptors.add(LoggingInterceptor());
  (dio.transformer as DefaultTransformer).jsonDecodeCallback = parseJson;
  dio.addSentry(captureFailedRequests: true);

  final authenticatedDio = Dio(); // Authenticated dio instance for AU servers
  authenticatedDio.interceptors.add(AutonomyAuthInterceptor());
  authenticatedDio.interceptors.add(LoggingInterceptor());
  (authenticatedDio.transformer as DefaultTransformer).jsonDecodeCallback =
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
  authenticatedDio.addSentry(captureFailedRequests: true);
  authenticatedDio.options = BaseOptions(followRedirects: true);

  // Services
  final auditService = AuditServiceImpl(cloudDB);

  injector.registerSingleton<ConfigurationService>(
      ConfigurationServiceImpl(sharedPreferences));

  injector.registerLazySingleton(() => Client());
  injector.registerLazySingleton(() => NavigationService());
  injector.registerLazySingleton(() => LedgerHardwareService());
  injector.registerLazySingleton<AutonomyService>(
      () => AutonomyServiceImpl(injector(), injector()));
  injector.registerLazySingleton<MetricClientService>(
      () => MetricClientService(injector()));
  injector.registerLazySingleton<MixPanelClientService>(
      () => MixPanelClientService(injector()));
  injector.registerLazySingleton(
      () => WalletConnectService(injector(), injector(), injector()));
  injector.registerLazySingleton<CacheManager>(() => AUImageCacheManage());
  injector.registerLazySingleton(() => WalletConnectDappService(injector()));
  injector.registerLazySingleton<AccountService>(() => AccountServiceImpl(
        cloudDB,
        injector(),
        injector(),
        injector(),
        auditService,
        injector(),
        injector(),
        injector(),
      ));

  injector.registerLazySingleton(
      () => IAPApi(authenticatedDio, baseUrl: Environment.autonomyAuthURL));
  injector.registerLazySingleton(() =>
      AutonomyApi(authenticatedDio, baseUrl: Environment.autonomyAuthURL));
  injector.registerLazySingleton(() => TZKTApi(dio));
  injector.registerLazySingleton(() => EtherchainApi(dio));
  injector.registerLazySingleton(() => BranchApi(dio));
  injector.registerLazySingleton(
      () => PubdocAPI(dio, baseUrl: Environment.pubdocURL));
  injector.registerLazySingleton(
      () => FeedApi(authenticatedDio, baseUrl: Environment.feedURL));
  injector.registerLazySingleton(
      () => AuthService(injector(), injector(), injector()));
  injector.registerLazySingleton(() => BackupService(injector()));

  final pendingTokenExpireMs = Environment.pendingTokenExpireMs;
  final nftBloc = await NftCollection.createBloc(
    indexerUrl: Environment.indexerURL,
    logger: log,
    apiLogger: apiLog,
    pendingTokenExpire: pendingTokenExpireMs != null
        ? Duration(milliseconds: pendingTokenExpireMs)
        : null,
  );
  injector.registerSingleton(nftBloc);
  injector.registerSingleton(nftBloc.tokensService);

  injector
      .registerLazySingleton<SettingsDataService>(() => SettingsDataServiceImpl(
            injector(),
            injector(),
            injector(),
          ));
  injector.registerLazySingleton<IAPService>(
      () => IAPServiceImpl(injector(), injector()));

  injector
      .registerLazySingleton(() => TezosBeaconService(injector(), injector()));
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
          ));

  injector.registerLazySingleton<AuditService>(() => auditService);

  final cloudService = CloudService();
  injector.registerLazySingleton(() => cloudService);

  injector.registerLazySingleton(
      () => Web3Client(Environment.web3RpcURL, injector()));
  injector.registerLazySingleton(
      () => TezartClient(Environment.tezosNodeClientURL));
  injector.registerLazySingleton<FeralFileApi>(() =>
      FeralFileApi(_feralFileDio(), baseUrl: Environment.feralFileAPIURL));
  injector.registerLazySingleton<BitmarkApi>(
      () => BitmarkApi(dio, baseUrl: Environment.bitmarkAPIURL));
  injector.registerLazySingleton<IndexerApi>(
      () => IndexerApi(dio, baseUrl: Environment.indexerURL));

  injector.registerLazySingleton<EthereumService>(
      () => EthereumServiceImpl(injector(), injector()));
  injector
      .registerLazySingleton<TezosService>(() => TezosServiceImpl(injector()));
  injector.registerLazySingleton<AppDatabase>(() => mainnetDB);

  injector
      .registerLazySingleton<FeedService>(() => FeedServiceImpl(injector()));

  injector.registerLazySingleton<FeralFileService>(() => FeralFileServiceImpl(
        injector(),
        injector(),
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
        nftBloc.database.assetDao,
      ));
  injector.registerFactory<AddNewPlaylistBloc>(() => AddNewPlaylistBloc());
  injector.registerFactory<ViewPlaylistBloc>(() => ViewPlaylistBloc());
  injector.registerFactory<EditPlaylistBloc>(() => EditPlaylistBloc());
  injector.registerSingleton<ValueNotifier<PlayControlService>>(
      ValueNotifier<PlayControlService>(
          PlayControlService(timer: 0, isLoop: false, isShuffle: false)));
}

Dio _feralFileDio() {
  final dio = Dio(); // Default a dio instance
  dio.interceptors.add(LoggingInterceptor());
  dio.interceptors.add(FeralfileAuthInterceptor());
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
  (dio.transformer as DefaultTransformer).jsonDecodeCallback = parseJson;
  dio.addSentry(captureFailedRequests: true);
  return dio;
}

parseJson(String text) {
  return IsolatedUtil().parseAndDecode(text);
}
