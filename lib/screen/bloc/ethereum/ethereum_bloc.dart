//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:bloc/bloc.dart';
import 'package:web3dart/web3dart.dart';

part 'ethereum_state.dart';

class EthereumBloc extends Bloc<EthereumEvent, EthereumState> {
  ConfigurationService _configurationService;
  EthereumService _ethereumService;

  EthereumBloc(this._configurationService, this._ethereumService)
      : super(EthereumState(ethBalances: {
          Network.MAINNET: {},
          Network.TESTNET: {},
        })) {
    on<GetEthereumAddressEvent>((event, emit) async {
      if (state.personaAddresses?[event.uuid] != null) return;
      final address =
          await Persona.newPersona(uuid: event.uuid).wallet().getETHEip55Address();
      var personaAddresses = state.personaAddresses ?? Map();
      personaAddresses[event.uuid] = address;

      emit(state.copyWith(personaAddresses: personaAddresses));
    });

    on<GetEthereumBalanceWithAddressEvent>((event, emit) async {
      final network = _configurationService.getNetwork();
      final ethBalance = await _ethereumService.getBalance(event.address);

      var ethBalances = state.ethBalances;
      state.ethBalances[network]![event.address] = ethBalance;

      emit(state.copyWith(ethBalances: ethBalances));
    });

    on<GetEthereumBalanceWithUUIDEvent>((event, emit) async {
      final address =
          await Persona.newPersona(uuid: event.uuid).wallet().getETHEip55Address();
      final network = _configurationService.getNetwork();

      final ethBalance = await _ethereumService.getBalance(address);
      var ethBalances = state.copyWith().ethBalances;
      ethBalances[network]![address] = ethBalance;

      emit(state.copyWith(ethBalances: ethBalances));
    });
  }
}
