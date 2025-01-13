//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/currency_exchange.dart';

abstract class WalletDetailEvent {}

class WalletDetailBalanceEvent extends WalletDetailEvent {
  WalletDetailBalanceEvent(this.address);

  String address;
}

class WalletDetailState {
  WalletDetailState({
    this.exchangeRate,
  });

  final CurrencyExchangeRate? exchangeRate;

  WalletDetailState copyWith({
    CurrencyExchangeRate? exchangeRate,
  }) =>
      WalletDetailState(
        exchangeRate: exchangeRate ?? this.exchangeRate,
      );
}
