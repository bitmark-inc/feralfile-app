import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/gateway/indexer_api.dart';
import 'package:autonomy_flutter/model/blockchain.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
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

    on<RefreshTokensEvent>((event, emit) async {
      try {
        final currentTokens = await _assetTokenDao.findAllAssetTokens();
        emit(HomeState(
            tokens: currentTokens, fetchTokenState: ActionState.loading));

        final linkedAccounts = await _cloudDB.connectionDao.getLinkedAccounts();
        final personas = await _cloudDB.personaDao.getPersonas();

        var accountNumbers =
            linkedAccounts.map((e) => e.accountNumber).toList();

        for (var persona in personas) {
          final ethAddress = await persona.wallet().getETHAddress();
          final tezosWallet = await persona.wallet().getTezosWallet();
          final tezosAddress = tezosWallet.address;

          accountNumbers += [ethAddress, tezosAddress];
        }

        List<AssetToken> allTokens = [];

        for (var accountNumber in accountNumbers) {
          final tokens = await _indexerApi.getNftTokensByOwner(accountNumber);
          allTokens += tokens.map((e) => AssetToken.fromAsset(e)).toList();
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

        // Reindex AccountNumber
        // TODO:

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
