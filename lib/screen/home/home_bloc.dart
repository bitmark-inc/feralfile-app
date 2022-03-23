import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/gateway/indexer_api.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/tokens_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:autonomy_flutter/util/log.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  TokensService _tokensService;
  WalletConnectService _walletConnectService;
  TezosBeaconService _tezosBeaconService;
  NetworkConfigInjector _networkConfigInjector;
  CloudDatabase _cloudDB;
  ConfigurationService _configurationService;

  AssetTokenDao get _assetTokenDao =>
      _networkConfigInjector.I<AppDatabase>().assetDao;
  IndexerApi get _indexerApi => _networkConfigInjector.I<IndexerApi>();

  HomeBloc(
      this._tokensService,
      this._walletConnectService,
      this._tezosBeaconService,
      this._networkConfigInjector,
      this._cloudDB,
      this._configurationService)
      : super(HomeState()) {
    on<HomeConnectWCEvent>((event, emit) {
      log.info('[HomeConnectWCEvent] connect ${event.uri}');
      _walletConnectService.connect(event.uri);
    });

    on<HomeConnectTZEvent>((event, emit) {
      log.info('[HomeConnectTZEvent] addPeer ${event.uri}');
      _tezosBeaconService.addPeer(event.uri);
    });

    on<RefreshTokensEvent>((event, emit) async {
      log.info("[HomeBloc] RefreshTokensEvent start");
      try {
        late List<String> allAccountNumbers;
        if (_configurationService.isDemoArtworksMode()) {
          allAccountNumbers = ["demo"];
        } else {
          final allAddresses = await _getPersonaAddresses();
          final linkedAccounts =
              await _cloudDB.connectionDao.getLinkedAccounts();
          var linkedAccountNumbers =
              linkedAccounts.map((e) => e.accountNumber).toList();

          allAccountNumbers = List.from(linkedAccountNumbers)
            ..addAll(allAddresses['personaBitmark'] ?? [])
            ..addAll(allAddresses['personaEthereum'] ?? [])
            ..addAll(allAddresses['personaTezos'] ?? []);
        }

        await _assetTokenDao.deleteAssetsNotBelongs(allAccountNumbers);
        final assetTokens = await _assetTokenDao.findAllAssetTokens();
        emit(state.copyWith(tokens: assetTokens));

        final firstTokensSize = assetTokens.isEmpty ? 20 : 50;

        final latestNFTs = await _tokensService.fetchLatestTokens(
            allAccountNumbers, firstTokensSize);
        await _assetTokenDao.insertAssets(latestNFTs);

        log.info("[HomeBloc] fetch ${latestNFTs.length} latest NFTs");

        if (latestNFTs.length < firstTokensSize) {
          // Delete obsoleted assets
          if (latestNFTs.isNotEmpty) {
            await _assetTokenDao
                .deleteAssetsNotIn(latestNFTs.map((e) => e.id).toList());
          } else {
            await _assetTokenDao.removeAll();
          }

          emit(state.copyWith(
              tokens: await _assetTokenDao.findAllAssetTokens()));
        } else {
          emit(state.copyWith(
              tokens: await _assetTokenDao.findAllAssetTokens()));
          log.info("[HomeBloc] _tokensService.refreshTokensInIsolate");

          await _tokensService.refreshTokensInIsolate(allAccountNumbers);
          emit(state.copyWith(
              tokens: await _assetTokenDao.findAllAssetTokens()));
        }
      } catch (exception) {
        if ((state.tokens ?? []).isEmpty) {
          rethrow;
        } else {
          Sentry.captureException(exception);
        }
      }
    });

    on<ReindexIndexerEvent>((event, emit) async {
      try {
        final addresses = await _getPersonaAddresses();

        for (var ethAddress in addresses['personaEthereum'] ?? []) {
          log.info("[HomeBloc] RequestIndex for $ethAddress");
          _indexerApi.requestIndex({"owner": ethAddress});
        }

        for (var tezosAddress in addresses['personaTezos'] ?? []) {
          log.info("[HomeBloc] RequestIndex for $tezosAddress");
          _indexerApi
              .requestIndex({"owner": tezosAddress, "blockchain": "tezos"});
        }

        final linkedAccounts = await _cloudDB.connectionDao.getLinkedAccounts();

        for (var linkAccount in linkedAccounts) {
          switch (linkAccount.connectionType) {
            case 'walletConnect':
              final ethAddress = linkAccount.accountNumber;
              log.info("[HomeBloc] RequestIndex for linked $ethAddress");
              _indexerApi.requestIndex({"owner": ethAddress});
              break;

            case 'walletBeacon':
              final tezosAddress = linkAccount.accountNumber;
              log.info("[HomeBloc] RequestIndex for linked $tezosAddress");
              _indexerApi
                  .requestIndex({"owner": tezosAddress, "blockchain": "tezos"});
              break;

            case 'manuallyAddress':
              final address = linkAccount.accountNumber;
              final isTezosAddress = address.startsWith("tz");
              log.info(
                  "[HomeBloc] RequestIndex for linked $address - isTezosAddress: $isTezosAddress");
              if (isTezosAddress) {
                _indexerApi
                    .requestIndex({"owner": address, "blockchain": "tezos"});
              } else {
                _indexerApi.requestIndex({"owner": address});
              }
              break;

            default:
              break;
          }
        }
      } catch (exception) {
        log.info("[HomeBloc] error when request index");
        Sentry.captureException(exception);
      }
    });
  }

  Future<Map<String, List<String>>> _getPersonaAddresses() async {
    final personas = await _cloudDB.personaDao.getPersonas();

    List<String> bitmarkAddresses = [];
    List<String> ethAddresses = [];
    List<String> tezosAddresses = [];

    for (var persona in personas) {
      final ethAddress = await persona.wallet().getETHAddress();
      final tezosWallet = await persona.wallet().getTezosWallet();
      final tezosAddress = tezosWallet.address;
      final bitmarkAddress = await persona.wallet().getBitmarkAddress();

      bitmarkAddresses += [bitmarkAddress];
      ethAddresses += [ethAddress];
      tezosAddresses += [tezosAddress];
    }

    return {
      'personaBitmark': bitmarkAddresses,
      'personaEthereum': ethAddresses,
      'personaTezos': tezosAddresses,
    };
  }
}
