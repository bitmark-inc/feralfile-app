//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:web3dart/web3dart.dart';

part 'ethereum_state.dart';

class EthereumBloc extends AuBloc<EthereumEvent, EthereumState> {
  final EthereumService _ethereumService;

  EthereumBloc(this._ethereumService) : super(EthereumState(null, {})) {
    on<GetEthereumAddressEvent>((event, emit) async {
      if (state.personaAddresses?[event.uuid] != null) return;
      final address = await Persona.newPersona(uuid: event.uuid)
          .wallet()
          .getETHEip55Address();
      var personaAddresses = state.personaAddresses ?? {};
      personaAddresses[event.uuid] = address;

      emit(state.copyWith(personaAddresses: personaAddresses));
    });

    on<GetEthereumBalanceWithAddressEvent>((event, emit) async {
      final ethBalance = await _ethereumService.getBalance(event.address);

      var ethBalances = state.ethBalances;
      state.ethBalances[event.address] = ethBalance;

      emit(state.copyWith(ethBalances: ethBalances));
    });

    on<GetEthereumBalanceWithUUIDEvent>((event, emit) async {
      final address = await Persona.newPersona(uuid: event.uuid)
          .wallet()
          .getETHEip55Address();

      final ethBalance = await _ethereumService.getBalance(address);
      var ethBalances = state.copyWith().ethBalances;
      ethBalances[address] = ethBalance;

      emit(state.copyWith(ethBalances: ethBalances));
    });
  }
}
