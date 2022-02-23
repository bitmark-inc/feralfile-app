import 'dart:developer';

import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/gateway/indexer_api.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  FeralFileService _feralFileService;
  WalletConnectService _walletConnectService;
  TezosBeaconService _tezosBeaconService;
  AssetTokenDao _assetTokenDao;
  IndexerApi _indexerApi;
  CloudDatabase _cloudDB;

  HomeBloc(
      this._feralFileService,
      this._walletConnectService,
      this._tezosBeaconService,
      this._assetTokenDao,
      this._indexerApi,
      this._cloudDB)
      : super(HomeState()) {
    on<HomeConnectWCEvent>((event, emit) {
      _walletConnectService.connect(event.uri);
    });

    on<HomeConnectTZEvent>((event, emit) {
      _tezosBeaconService.addPeer(event.uri);
    });

    void _requestIndex(List<String> ethAddresses, List<String> tezosAddresses,
        List<Connection> linkedAccounts) {
      for (var ethAddress in ethAddresses) {
        log("[HomeBloc] RequestIndex for $ethAddress");
        _indexerApi.requestIndex({"owner": ethAddress});
      }

      for (var tezosAddress in tezosAddresses) {
        log("[HomeBloc] RequestIndex for $tezosAddress");
        _indexerApi
            .requestIndex({"owner": tezosAddress, "blockchain": "tezos"});
      }

      for (var linkAccount in linkedAccounts) {
        switch (linkAccount.connectionType) {
          case 'walletConnect':
            final ethAddress = linkAccount.accountNumber;
            log("[HomeBloc] RequestIndex for linked $ethAddress");
            _indexerApi.requestIndex({"owner": ethAddress});
            break;

          case 'walletBeacon':
            final tezosAddress = linkAccount.accountNumber;
            log("[HomeBloc] RequestIndex for linked $tezosAddress");
            _indexerApi
                .requestIndex({"owner": tezosAddress, "blockchain": "tezos"});
            break;

          default:
            break;
        }
      }
    }

    on<RefreshTokensEvent>((event, emit) async {
      try {
        final currentTokens = await _assetTokenDao.findAllAssetTokens();
        emit(HomeState(
            tokens: currentTokens, fetchTokenState: ActionState.loading));

        final linkedAccounts = await _cloudDB.connectionDao.getLinkedAccounts();
        final personas = await _cloudDB.personaDao.getPersonas();

        var accountNumbers =
            linkedAccounts.map((e) => e.accountNumber).toList();
        List<String> ethAddresses = [];
        List<String> tezosAddresses = [];

        for (var persona in personas) {
          final ethAddress = await persona.wallet().getETHAddress();
          final tezosWallet = await persona.wallet().getTezosWallet();
          final tezosAddress = tezosWallet.address;

          ethAddresses += [ethAddress];
          tezosAddresses += [tezosAddress];
        }
        List allAccountNumbers = List.from(accountNumbers)
          ..addAll(ethAddresses)
          ..addAll(tezosAddresses);

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

        // Request ReIndex
        try {
          _requestIndex(ethAddresses, tezosAddresses, linkedAccounts);
        } catch (exception) {
          log("[HomeBloc] error when request index");
          Sentry.captureException(exception);
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
  }
}
