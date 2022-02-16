import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/xtz_amount_formatter.dart';
import 'package:bloc/bloc.dart';

part 'tezos_state.dart';

class TezosBloc extends Bloc<TezosEvent, TezosState> {
  ConfigurationService _configurationService;
  TezosService _tezosService;

  TezosBloc(this._configurationService, this._tezosService)
      : super(TezosState(balances: {
          Network.MAINNET: {},
          Network.TESTNET: {},
        })) {
    on<GetTezosAddressEvent>((event, emit) async {
      if (state.personaAddresses?[event.uuid] != null) return;
      final tezosWallet =
          await Persona.newPersona(uuid: event.uuid).wallet().getTezosWallet();
      final address = tezosWallet.address;
      var personaAddresses = state.personaAddresses ?? Map();
      personaAddresses[event.uuid] = address;

      emit(state.copyWith(personaAddresses: personaAddresses));
    });

    on<GetTezosBalanceWithAddressEvent>((event, emit) async {
      final network = _configurationService.getNetwork();
      final balance = await _tezosService.getBalance(event.address);

      var balances = state.balances;
      balances[network]![event.address] = balance;

      emit(state.copyWith(balances: balances));

      // final xtzBalanceStr = "${XtzAmountFormatter(xtzBalance).format()} XTZ";
    });

    on<GetTezosBalanceWithUUIDEvent>((event, emit) async {
      final tezosWallet =
          await Persona.newPersona(uuid: event.uuid).wallet().getTezosWallet();
      final address = tezosWallet.address;
      final network = _configurationService.getNetwork();

      final balance = await _tezosService.getBalance(address);

      var balances = state.balances;
      balances[network]![address] = balance;

      emit(state.copyWith(balances: balances));
    });
  }
}
