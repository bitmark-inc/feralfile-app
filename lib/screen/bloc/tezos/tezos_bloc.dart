//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';

part 'tezos_state.dart';

class TezosBloc extends AuBloc<TezosEvent, TezosState> {
  final ConfigurationService _configurationService;
  final TezosService _tezosService;

  TezosBloc(this._configurationService, this._tezosService)
      : super(TezosState(null, {
          Network.MAINNET: {},
          Network.TESTNET: {},
        })) {
    on<GetTezosAddressEvent>((event, emit) async {
      if (state.personaAddresses?[event.uuid] != null) return;
      final tezosWallet =
          await Persona.newPersona(uuid: event.uuid).wallet().getTezosWallet();
      final address = tezosWallet.address;
      var personaAddresses = state.personaAddresses ?? {};
      personaAddresses[event.uuid] = address;

      emit(state.copyWith(personaAddresses: personaAddresses));
    });

    on<GetTezosBalanceWithAddressEvent>((event, emit) async {
      final network = _configurationService.getNetwork();
      final balance = await _tezosService.getBalance(event.address);

      var balances = state.balances;
      balances[network]![event.address] = balance;

      emit(state.copyWith(balances: balances));
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
