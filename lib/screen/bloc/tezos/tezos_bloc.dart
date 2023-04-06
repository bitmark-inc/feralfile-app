//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/constants.dart';

part 'tezos_state.dart';

class TezosBloc extends AuBloc<TezosEvent, TezosState> {
  final TezosService _tezosService;
  final CloudDatabase _cloudDB;

  TezosBloc(this._tezosService, this._cloudDB) : super(TezosState(null, {})) {
    on<GetTezosAddressEvent>((event, emit) async {
      if (state.personaAddresses?[event.uuid] != null) return;

      final walletAddresses = await _cloudDB.addressDao
          .getAddresses(event.uuid, CryptoType.XTZ.source);
      var personaAddresses = state.personaAddresses ?? {};
      personaAddresses[event.uuid] = walletAddresses;

      emit(state.copyWith(personaAddresses: personaAddresses));
    });

    on<GetTezosBalanceWithAddressEvent>((event, emit) async {
      var tezosBalances = state.balances;
      await Future.wait(event.addresses.map((address) async {
        tezosBalances[address] = await _tezosService.getBalance(address);
      }).toList());

      emit(state.copyWith(balances: tezosBalances));
    });

    on<GetTezosBalanceWithUUIDEvent>((event, emit) async {
      final walletAddresses = await _cloudDB.addressDao
          .getAddresses(event.uuid, CryptoType.XTZ.source);
      if (walletAddresses.isEmpty) {
        emit(state.copyWith(personaAddresses: {}));
        return;
      }
      var listAddresses = state.personaAddresses ?? {};
      listAddresses[event.uuid] = walletAddresses;
      emit(state.copyWith(personaAddresses: listAddresses));
      add(GetTezosBalanceWithAddressEvent(
          walletAddresses.map((e) => e.address).toList()));
    });
  }
}
