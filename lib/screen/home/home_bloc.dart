import 'dart:developer';

import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/gateway/indexer_api.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:autonomy_flutter/util/log.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  WalletConnectService _walletConnectService;
  TezosBeaconService _tezosBeaconService;
  AssetTokenDao _assetTokenDao;
  IndexerApi _indexerApi;
  CloudDatabase _cloudDB;
  ConfigurationService _configurationService;

  HomeBloc(
      this._walletConnectService,
      this._tezosBeaconService,
      this._assetTokenDao,
      this._indexerApi,
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
      try {
        final currentTokens = await _assetTokenDao.findAllAssetTokens();
        emit(HomeState(
            tokens: currentTokens, fetchTokenState: ActionState.loading));

        late List allAccountNumbers;
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

        List<AssetToken> allTokens = [];

        for (var accountNumber in allAccountNumbers) {
          var offset = 0;

          while (true) {
            final tokens =
                await _indexerApi.getNftTokensByOwner(accountNumber, offset);
            allTokens += tokens.map((e) => AssetToken.fromAsset(e)).toList();

            if (tokens.length < INDEXER_TOKENS_MAXIMUM) {
              break;
            } else {
              offset += INDEXER_TOKENS_MAXIMUM;
            }
          }
        }

        // Insert with con
        await _assetTokenDao.insertAssets(allTokens);
        // Delete no longer own assets
        if (allTokens.isNotEmpty) {
          await _assetTokenDao
              .deleteAssetsNotIn(allTokens.map((e) => e.id).toList());
        } else {
          await _assetTokenDao.removeAll();
        }

        // reload
        final tokens = await _assetTokenDao.findAllAssetTokens();
        emit(HomeState(tokens: tokens, fetchTokenState: ActionState.done));
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
