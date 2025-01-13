//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_state.dart';
import 'package:autonomy_flutter/service/currency_service.dart';

class WalletDetailBloc extends AuBloc<WalletDetailEvent, WalletDetailState> {
  WalletDetailBloc(
    this._currencyService,
  ) : super(WalletDetailState()) {
    on<WalletDetailBalanceEvent>((event, emit) async {
      final exchangeRate = await _currencyService.getExchangeRates();
      emit(
        state.copyWith(
          exchangeRate: exchangeRate,
        ),
      );
    });
  }

  final CurrencyService _currencyService;
}
