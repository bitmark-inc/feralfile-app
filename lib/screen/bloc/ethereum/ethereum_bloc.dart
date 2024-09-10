//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_object.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:web3dart/web3dart.dart';

part 'ethereum_state.dart';

class EthereumBloc extends AuBloc<EthereumEvent, EthereumState> {
  final EthereumService _ethereumService;
  final CloudObjects _cloudObject;

  EthereumBloc(this._ethereumService, this._cloudObject)
      : super(EthereumState(null, {})) {
    on<GetEthereumAddressEvent>((event, emit) {
      if (state.walletAddresses?[event.uuid] != null) {
        return;
      }
      final walletAddresses = _cloudObject.addressObject
          .getAddresses(event.uuid, CryptoType.ETH.source);
      var addresses = state.walletAddresses ?? {};
      addresses[event.uuid] = walletAddresses;

      emit(state.copyWith(walletAddresses: addresses));
    });

    on<GetEthereumBalanceWithAddressEvent>((event, emit) async {
      var ethBalances = state.ethBalances;
      await Future.wait(event.addresses.map((address) async {
        ethBalances[address] = await _ethereumService.getBalance(address);
      }).toList());
      emit(state.copyWith(ethBalances: ethBalances));
    });

    on<GetEthereumBalanceWithUUIDEvent>((event, emit) async {
      final walletAddresses = _cloudObject.addressObject
          .getAddresses(event.uuid, CryptoType.ETH.source);

      if (walletAddresses.isEmpty) {
        emit(state.copyWith(walletAddresses: {}));
        return;
      }
      var listAddresses = state.walletAddresses ?? {};
      listAddresses[event.uuid] = walletAddresses;
      emit(state.copyWith(walletAddresses: listAddresses));
      add(GetEthereumBalanceWithAddressEvent(
          walletAddresses.map((e) => e.address).toList()));
    });
  }
}
