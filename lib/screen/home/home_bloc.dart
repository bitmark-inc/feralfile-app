import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeBloc extends Bloc<HomeEvent, int> {
  WalletConnectService _walletConnectService;

  HomeBloc(this._walletConnectService) : super(0) {
    on<HomeConnectWCEvent>((event, emit) {
      _walletConnectService.connect(event.uri);
    });
  }
}