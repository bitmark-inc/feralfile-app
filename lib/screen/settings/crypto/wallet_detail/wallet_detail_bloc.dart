//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_state.dart';
import 'package:autonomy_flutter/service/currency_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';

class WalletDetailBloc extends AuBloc<WalletDetailEvent, WalletDetailState> {
  final EthereumService _ethereumService;
  final TezosService _tezosService;
  final CurrencyService _currencyService;
  final ethFormatter = EthAmountFormatter();
  final xtzFormatter = XtzAmountFormatter();

  WalletDetailBloc(
      this._ethereumService, this._tezosService, this._currencyService)
      : super(WalletDetailState()) {
    on<WalletDetailBalanceEvent>((event, emit) async {
      final exchangeRate = await _currencyService.getExchangeRates();
      String balanceS = '';
      String balanceInUSD = '';

      switch (event.type) {
        case CryptoType.ETH:
          final balance = await _ethereumService.getBalance(event.address);
          balanceS = '${ethFormatter.format(balance.getInWei)} ETH';
          final usdBalance = exchangeRate.ethToUsd(balance.getInWei);
          balanceInUSD = '$usdBalance USD';
        case CryptoType.XTZ:
          final balance = await _tezosService.getBalance(event.address);
          balanceS = '${xtzFormatter.format(balance)} XTZ';
          final usdBalance = exchangeRate.xtzToUsd(balance);
          balanceInUSD = '$usdBalance USD';

        default:
      }

      emit(state.copyWith(
        balance: balanceS,
        balanceInUSD: balanceInUSD,
      ));
    });
  }
}
