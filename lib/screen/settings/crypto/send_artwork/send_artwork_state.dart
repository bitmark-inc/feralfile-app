//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/currency_exchange.dart';
import 'package:libauk_dart/libauk_dart.dart';

abstract class SendArtworkEvent {}

class GetBalanceEvent extends SendArtworkEvent {
  final WalletStorage wallet;

  GetBalanceEvent(this.wallet);
}

class AddressChangedEvent extends SendArtworkEvent {
  final String address;

  AddressChangedEvent(this.address);
}

class EstimateFeeEvent extends SendArtworkEvent {
  final String address;
  final String contractAddress;
  final String tokenId;

  EstimateFeeEvent(this.address, this.contractAddress, this.tokenId);
}

class SendArtworkState {
  WalletStorage? wallet;

  bool isScanQR;
  bool isAddressError;
  bool isValid;

  BigInt? fee;
  String? address;
  BigInt? balance;

  CurrencyExchangeRate exchangeRate;

  bool isEstimating = false;

  SendArtworkState(
      {this.wallet,
        this.isScanQR = true,
        this.isAddressError = false,
        this.isValid = false,
        this.fee,
        this.address,
        this.balance,
        this.exchangeRate = const CurrencyExchangeRate(eth: "1.0", xtz: "1.0")});

  SendArtworkState clone() => SendArtworkState(
    wallet: wallet,
    isScanQR: isScanQR,
    isAddressError: isAddressError,
    isValid: isValid,
    fee: fee,
    address: address,
    exchangeRate: exchangeRate,
    balance: balance,
  );
}
