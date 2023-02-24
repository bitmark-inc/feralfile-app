//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';

part 'tezos_state.dart';

class TezosBloc extends AuBloc<TezosEvent, TezosState> {
  final TezosService _tezosService;
  final CloudDatabase _cloudDB;

  TezosBloc(this._tezosService, this._cloudDB) : super(TezosState(null, {})) {
    on<GetTezosAddressEvent>((event, emit) async {
      if (state.personaAddresses?[event.uuid] != null) return;
      final persona = await _cloudDB.personaDao.findById(event.uuid);
      if (persona == null || persona.tezosIndex < 1) return;
      final addresses = await persona.getTezosAddresses();
      var personaAddresses = state.personaAddresses ?? {};
      personaAddresses[event.uuid] = addresses;

      emit(state.copyWith(personaAddresses: personaAddresses));
    });

    on<GetTezosBalanceWithAddressEvent>((event, emit) async {
      var tezosBalances = state.balances;
      for (var address in event.addresses) {
        final tezosBalance = await _tezosService.getBalance(address);
        tezosBalances[address] = tezosBalance;
      }
      emit(state.copyWith(balances: tezosBalances));
    });

    on<GetTezosBalanceWithUUIDEvent>((event, emit) async {
      final persona = await _cloudDB.personaDao.findById(event.uuid);
      if (persona == null || persona.tezosIndex < 1) return;
      final addresses = await persona.getTezosAddresses();

      add(GetTezosBalanceWithAddressEvent(addresses));
    });
  }
}
