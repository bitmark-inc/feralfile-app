//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';

part 'tezos_state.dart';

class TezosBloc extends AuBloc<TezosEvent, TezosState> {
  final TezosService _tezosService;

  TezosBloc(this._tezosService) : super(TezosState(null, {})) {
    on<GetTezosAddressEvent>((event, emit) async {
      if (state.personaAddresses?[event.uuid] != null) return;
      final address =
          await Persona.newPersona(uuid: event.uuid).wallet().getTezosAddress();
      var personaAddresses = state.personaAddresses ?? {};
      personaAddresses[event.uuid] = address;

      emit(state.copyWith(personaAddresses: personaAddresses));
    });

    on<GetTezosBalanceWithAddressEvent>((event, emit) async {
      final balance = await _tezosService.getBalance(event.address);

      var balances = state.balances;
      balances[event.address] = balance;

      emit(state.copyWith(balances: balances));
    });

    on<GetTezosBalanceWithUUIDEvent>((event, emit) async {
      final address =
          await Persona.newPersona(uuid: event.uuid).wallet().getTezosAddress();

      final balance = await _tezosService.getBalance(address);

      var balances = state.balances;
      balances[address] = balance;

      emit(state.copyWith(balances: balances));
    });
  }
}
