//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:web3dart/web3dart.dart';

part 'usdc_state.dart';

class USDCBloc extends AuBloc<USDCEvent, USDCState> {
  final EthereumService _ethereumService;

  USDCBloc(this._ethereumService) : super(USDCState(null, {})) {
    on<GetAddressEvent>((event, emit) async {
      if (state.walletAddresses?[event.uuid] != null) {
        return;
      }
      final address = await WalletStorage(event.uuid)
          .getETHEip55Address(index: event.index);
      var addresses = state.walletAddresses ?? {};
      addresses[event.uuid] = address;

      emit(state.copyWith(walletAddresses: addresses));
    });

    on<GetUSDCBalanceWithAddressEvent>((event, emit) async {
      final contractAddress = EthereumAddress.fromHex(usdcContractAddress);
      final owner = EthereumAddress.fromHex(event.address);

      final usdcBalance =
          await _ethereumService.getERC20TokenBalance(contractAddress, owner);

      var ethBalances = state.usdcBalances;
      state.usdcBalances[event.address] = usdcBalance;

      emit(state.copyWith(usdcBalances: ethBalances));
    });

    on<GetUSDCBalanceWithUUIDEvent>((event, emit) async {
      final address = await WalletStorage(event.uuid)
          .getETHEip55Address(index: event.index);

      final contractAddress = EthereumAddress.fromHex(usdcContractAddress);
      final owner = EthereumAddress.fromHex(address);
      final usdcBalance =
          await _ethereumService.getERC20TokenBalance(contractAddress, owner);

      var ethBalances = state.copyWith().usdcBalances;
      ethBalances[address] = usdcBalance;

      emit(state.copyWith(usdcBalances: ethBalances));
    });
  }
}
