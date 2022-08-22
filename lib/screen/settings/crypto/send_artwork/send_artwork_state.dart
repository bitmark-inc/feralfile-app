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

class QuantityUpdateEvent extends SendArtworkEvent {
  final int quantity;
  final int maxQuantity;

  QuantityUpdateEvent({required this.quantity, required this.maxQuantity});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuantityUpdateEvent &&
          runtimeType == other.runtimeType &&
          quantity == other.quantity &&
          maxQuantity == other.maxQuantity;

  @override
  int get hashCode => quantity.hashCode ^ maxQuantity.hashCode;
}

class EstimateFeeEvent extends SendArtworkEvent {
  final String address;
  final String contractAddress;
  final String tokenId;
  final int quantity;

  EstimateFeeEvent(
      this.address, this.contractAddress, this.tokenId, this.quantity);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstimateFeeEvent &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          contractAddress == other.contractAddress &&
          tokenId == other.tokenId &&
          quantity == other.quantity;

  @override
  int get hashCode =>
      address.hashCode ^
      contractAddress.hashCode ^
      tokenId.hashCode ^
      quantity.hashCode;
}

class SendArtworkState {
  WalletStorage? wallet;

  bool isScanQR;
  bool isAddressError;
  bool isQuantityError;
  bool isValid;

  BigInt? fee;
  String? address;
  BigInt? balance;

  CurrencyExchangeRate exchangeRate;

  bool isEstimating = false;

  int quantity;

  SendArtworkState(
      {this.wallet,
        this.isScanQR = true,
        this.isAddressError = false,
        this.isQuantityError = false,
        this.isValid = false,
        this.fee,
        this.address,
        this.balance,
        this.exchangeRate = const CurrencyExchangeRate(eth: "1.0", xtz: "1.0"),
        this.quantity = 1});

  SendArtworkState clone() => SendArtworkState(
    wallet: wallet,
    isScanQR: isScanQR,
    isAddressError: isAddressError,
    isQuantityError: isQuantityError,
    isValid: isValid,
    fee: fee,
    address: address,
    exchangeRate: exchangeRate,
    balance: balance,
    quantity: quantity,
  );

  SendArtworkState copyWith({int? quantity}) {
    return SendArtworkState(
        wallet: wallet,
        isScanQR: isScanQR,
        isAddressError: isAddressError,
        isQuantityError: isQuantityError,
        isValid: isValid,
        fee: fee,
        address: address,
        exchangeRate: exchangeRate,
        balance: balance,
        quantity: quantity ?? this.quantity
    );
  }
}
