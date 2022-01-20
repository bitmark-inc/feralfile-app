import 'package:autonomy_flutter/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/model/blockchain.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  FeralFileService _feralFileService;
  WalletConnectService _walletConnectService;
  AssetTokenDao _assetTokenDao;

  HomeBloc(this._feralFileService, this._walletConnectService, this._assetTokenDao) : super(HomeState()) {
    on<HomeConnectWCEvent>((event, emit) {
      _walletConnectService.connect(event.uri);
    });

    on<HomeCheckFeralFileLoginEvent>((event, emit) async {
      final accountNumber = _feralFileService.getAccountNumber();

      if (accountNumber.isEmpty) {
        HomeState newState = HomeState();
        newState.isFeralFileLoggedIn = false;
        emit(newState);
      } else {
        // request index
        _feralFileService.requestIndex();

        // preload with local database
        HomeState localState = HomeState();
        localState.isFeralFileLoggedIn = true;

        localState.ffAssets = await _assetTokenDao.findAssetTokensByBlockchain("bitmark");
        localState.ethAssets = await _assetTokenDao.findAssetTokensByBlockchain("ethereum");
        localState.xtzAssets = await _assetTokenDao.findAssetTokensByBlockchain("tezos");
        emit(localState);

        // sync with remote
        HomeState remoteState = HomeState();
        remoteState.isFeralFileLoggedIn = true;

        final assets = await _feralFileService.getNftAssets();
        remoteState.ffAssets = assets[Blockchain.BITMARK] ?? [];
        remoteState.ethAssets = assets[Blockchain.ETHEREUM] ?? [];
        remoteState.xtzAssets = assets[Blockchain.TEZOS] ?? [];
        emit(remoteState);
      }
    });
  }
}