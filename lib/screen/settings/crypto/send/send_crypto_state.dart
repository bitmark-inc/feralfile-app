//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/currency_exchange.dart';
import 'package:libauk_dart/libauk_dart.dart';

abstract class SendCryptoEvent {}

class GetBalanceEvent extends SendCryptoEvent {
  final WalletStorage wallet;

  GetBalanceEvent(this.wallet);
}

class AmountChangedEvent extends SendCryptoEvent {
  final String amount;

  AmountChangedEvent(this.amount);
}

class AddressChangedEvent extends SendCryptoEvent {
  final String address;

  AddressChangedEvent(this.address);
}

class CurrencyTypeChangedEvent extends SendCryptoEvent {
  final bool isCrypto;

  CurrencyTypeChangedEvent(this.isCrypto);
}

class EstimateFeeEvent extends SendCryptoEvent {
  final String address;
  final BigInt amount;

  EstimateFeeEvent(this.address, this.amount);
}

class SendCryptoState {
  WalletStorage? wallet;

  bool isScanQR;
  bool isCrypto;

  bool isAddressError;
  bool isAmountError;

  bool isValid;

  String? address;
  BigInt? amount;
  BigInt? fee;
  BigInt? maxAllow;
  BigInt? balance;
  BigInt? ethBalance;

  CurrencyExchangeRate exchangeRate;

  SendCryptoState(
      {this.wallet,
      this.isScanQR = true,
      this.isCrypto = true,
      this.isAddressError = false,
      this.isAmountError = false,
      this.isValid = false,
      this.address,
      this.amount,
      this.fee,
      this.maxAllow,
      this.balance,
      this.ethBalance,
      this.exchangeRate = const CurrencyExchangeRate(eth: "1.0", xtz: "1.0")});

  SendCryptoState clone() => SendCryptoState(
        wallet: wallet,
        isScanQR: isScanQR,
        isCrypto: isCrypto,
        isAddressError: isAddressError,
        isAmountError: isAmountError,
        isValid: isValid,
        address: address,
        amount: amount,
        fee: fee,
        maxAllow: maxAllow,
        balance: balance,
        ethBalance: ethBalance,
        exchangeRate: exchangeRate,
      );
}
