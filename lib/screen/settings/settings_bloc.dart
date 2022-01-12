import 'package:autonomy_flutter/screen/settings/settings_state.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/xtz_amount_formatter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  EthereumService _ethereumService;
  TezosService _tezosService;

  SettingsBloc(this._ethereumService, this._tezosService)
      : super(SettingsState()) {
    on<SettingsGetBalanceEvent>((event, emit) async {
      final ethAddress = await _ethereumService.getETHAddress();
      final ethBalance = await _ethereumService.getBalance(ethAddress);

      state.ethBalance =
          "${EthAmountFormatter(ethBalance.getInWei).format()} ETH";

      final xtzAddress = await _tezosService.getTezosAddress();
      final xtzBalance = await _tezosService.getBalance(xtzAddress);

      state.xtzBalance = "${XtzAmountFormatter(xtzBalance).format()} XTZ";

      emit(state);
    });
  }
}
