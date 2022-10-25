//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:math';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_state.dart';
import 'package:autonomy_flutter/service/currency_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:flutter/material.dart';

class WalletDetailBloc extends AuBloc<WalletDetailEvent, WalletDetailState> {
  final EthereumService _ethereumService;
  final TezosService _tezosService;
  final CurrencyService _currencyService;

  WalletDetailBloc(
      this._ethereumService, this._tezosService, this._currencyService)
      : super(WalletDetailState()) {
    on<WalletDetailBalanceEvent>((event, emit) async {
      final exchangeRate = await _currencyService.getExchangeRates();
      final newState = WalletDetailState();

      switch (event.type) {
        case CryptoType.ETH:
          final address = await event.wallet.getETHEip55Address();
          emit(state.copyWith(address: address));
          final balance = await _ethereumService.getBalance(address);

          newState.address = address;
          newState.balance =
              "${EthAmountFormatter(balance.getInWei).format().characters.take(7)} ETH";
          newState.balanceInUSD = "${(balance.getInWei.toDouble() /
                      pow(10, 18) /
                      double.parse(exchangeRate.eth))
                  .toStringAsPrecision(2)} USD";
          break;
        case CryptoType.XTZ:
          final address = await event.wallet.getTezosAddress();
          emit(state.copyWith(address: address));

          final balance = await _tezosService.getBalance(address);

          newState.address = address;
          newState.balance = "${XtzAmountFormatter(balance).format()} XTZ";
          newState.balanceInUSD =
              "${(balance / pow(10, 6) / double.parse(exchangeRate.xtz))
                      .toStringAsFixed(2)} USD";

          break;
        case CryptoType.BITMARK:
          // TODO: Handle this case.
          break;
      }

      emit(newState);
    });
  }
}
