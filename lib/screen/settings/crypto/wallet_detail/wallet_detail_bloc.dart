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
import 'package:autonomy_flutter/util/fiat_formater.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';

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
          final balance = await _ethereumService.getBalance(event.address);
          newState.balance =
              '${EthAmountFormatter(balance.getInWei).format()} ETH';
          final usdBalance = balance.getInWei.toDouble() /
              pow(10, 18) *
              double.parse(exchangeRate.eth);
          final balanceInUSD = '${FiatFormatter(usdBalance).format()} USD';
          newState.balanceInUSD = balanceInUSD;
          break;
        case CryptoType.XTZ:
          final balance = await _tezosService.getBalance(event.address);
          newState.balance = '${XtzAmountFormatter(balance).format()} XTZ';
          final usdBalance =
              balance / pow(10, 6) / double.parse(exchangeRate.xtz);
          final balanceInUSD = '${FiatFormatter(usdBalance).format()} USD';
          newState.balanceInUSD = balanceInUSD;

          break;
        default:
          break;
      }

      emit(newState);
    });
  }
}
