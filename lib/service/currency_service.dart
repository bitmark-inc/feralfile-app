//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/gateway/currency_exchange_api.dart';
import 'package:autonomy_flutter/model/currency_exchange.dart';

abstract class CurrencyService {
  Future<CurrencyExchangeRate> getExchangeRates();
}

class CurrencyServiceImpl extends CurrencyService {
  CurrencyExchangeApi _currencyExchangeApi;

  CurrencyServiceImpl(this._currencyExchangeApi);

  @override
  Future<CurrencyExchangeRate> getExchangeRates() async {
    final response = await _currencyExchangeApi.getExchangeRates();

    return response["data"]?.rates ??
        CurrencyExchangeRate(eth: "1.0", xtz: "1.0");
  }
}
