import 'package:autonomy_flutter/screen/settings/settings_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/xtz_amount_formatter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {

  ConfigurationService _configurationService;
  EthereumService _ethereumService;
  TezosService _tezosService;

  SettingsBloc(this._configurationService, this._ethereumService, this._tezosService)
      : super(SettingsState()) {
    on<SettingsGetBalanceEvent>((event, emit) async {
      final network = _configurationService.getNetwork();
      emit(SettingsState(network: network));

      final ethAddress = await _ethereumService.getETHAddress();
      final ethBalance = await _ethereumService.getBalance(ethAddress);

      final ethBalanceStr =
          "${EthAmountFormatter(ethBalance.getInWei).format()} ETH";

      final xtzAddress = await _tezosService.getTezosAddress();
      final xtzBalance = await _tezosService.getBalance(xtzAddress);

      final xtzBalanceStr = "${XtzAmountFormatter(xtzBalance).format()} XTZ";

      emit(SettingsState(ethBalance: ethBalanceStr, xtzBalance: xtzBalanceStr, network: network));
    });
  }
}
