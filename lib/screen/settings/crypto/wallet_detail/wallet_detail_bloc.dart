//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_state.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/currency_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/wallet_address_ext.dart';
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
      final newState = WalletDetailState();

      switch (event.type) {
        case CryptoType.ETH:
          final balance = await _ethereumService.getBalance(event.address);
          newState.balance = '${ethFormatter.format(balance.getInWei)} ETH';
          final usdBalance = exchangeRate.ethToUsd(balance.getInWei);
          final balanceInUSD = '$usdBalance USD';
          newState.balanceInUSD = balanceInUSD;
        case CryptoType.XTZ:
          final balance = await _tezosService.getBalance(event.address);
          newState.balance = '${xtzFormatter.format(balance)} XTZ';
          final usdBalance = exchangeRate.xtzToUsd(balance);
          final balanceInUSD = '$usdBalance USD';
          newState.balanceInUSD = balanceInUSD;

        default:
      }

      emit(newState);
    });

    on<WalletDetailPrimaryAddressEvent>((event, emit) async {
      final primaryAddressInfo =
          await injector<AddressService>().getPrimaryAddressInfo();

      final newState = state.copyWith(
        isPrimary: event.walletAddress.isMatchAddressInfo(primaryAddressInfo),
      );

      emit(newState);
    });
  }
}
