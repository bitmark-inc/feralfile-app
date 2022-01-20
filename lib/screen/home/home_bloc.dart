import 'package:autonomy_flutter/model/blockchain.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  FeralFileService _feralFileService;
  WalletConnectService _walletConnectService;

  HomeBloc(this._feralFileService, this._walletConnectService) : super(HomeState()) {
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
        await _feralFileService.requestIndex();

        HomeState newState = HomeState();
        newState.isFeralFileLoggedIn = true;

        final assets = await _feralFileService.getNftAssets();
        newState.ffAssets = assets[Blockchain.BITMARK] ?? [];
        newState.ethAssets = assets[Blockchain.ETHEREUM] ?? [];
        newState.xtzAssets = assets[Blockchain.TEZOS] ?? [];
        emit(newState);
      }
    });
  }
}