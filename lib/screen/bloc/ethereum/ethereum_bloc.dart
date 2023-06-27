//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:web3dart/web3dart.dart';

part 'ethereum_state.dart';

class EthereumBloc extends AuBloc<EthereumEvent, EthereumState> {
  final EthereumService _ethereumService;
  final CloudDatabase _cloudDB;

  EthereumBloc(this._ethereumService, this._cloudDB)
      : super(EthereumState(null, {})) {
    on<GetEthereumAddressEvent>((event, emit) async {
      if (state.personaAddresses?[event.uuid] != null) return;
      final walletAddresses = await _cloudDB.addressDao
          .getAddresses(event.uuid, CryptoType.ETH.source);
      var personaAddresses = state.personaAddresses ?? {};
      personaAddresses[event.uuid] = walletAddresses;

      emit(state.copyWith(personaAddresses: personaAddresses));
    });

    on<GetEthereumBalanceWithAddressEvent>((event, emit) async {
      var ethBalances = state.ethBalances;
      await Future.wait((event.addresses.map((address) async {
        ethBalances[address] = await _ethereumService.getBalance(address);
      })).toList());
      emit(state.copyWith(ethBalances: ethBalances));
    });

    on<GetEthereumBalanceWithUUIDEvent>((event, emit) async {
      final walletAddresses = await _cloudDB.addressDao
          .getAddresses(event.uuid, CryptoType.ETH.source);

      if (walletAddresses.isEmpty) {
        emit(state.copyWith(personaAddresses: {}));
        return;
      }
      var listAddresses = state.personaAddresses ?? {};
      listAddresses[event.uuid] = walletAddresses;
      emit(state.copyWith(personaAddresses: listAddresses));
      add(GetEthereumBalanceWithAddressEvent(
          walletAddresses.map((e) => e.address).toList()));
    });
  }
}
