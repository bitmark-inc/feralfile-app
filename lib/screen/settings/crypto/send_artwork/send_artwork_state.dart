//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/currency_exchange.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/fee_util.dart';
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
  final SendArtworkState? newState;

  EstimateFeeEvent(
      this.address, this.contractAddress, this.tokenId, this.quantity,
      {this.newState});

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

class FeeOptionChangedEvent extends SendArtworkEvent {
  final FeeOption feeOption;
  final String address;
  final int quantity;

  FeeOptionChangedEvent(this.feeOption, this.address, this.quantity);
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

  FeeOption feeOption;
  FeeOptionValue? feeOptionValue;

  CurrencyExchangeRate exchangeRate;

  bool isEstimating = false;

  int quantity;

  SendArtworkState(
      {this.wallet,
      this.isScanQR = true,
      this.isAddressError = false,
      this.isQuantityError = false,
      this.isEstimating = false,
      this.isValid = false,
      this.fee,
      this.address,
      this.balance,
      this.exchangeRate = const CurrencyExchangeRate(eth: "1.0", xtz: "1.0"),
      this.quantity = 1,
      this.feeOption = DEFAULT_FEE_OPTION,
      this.feeOptionValue});

  SendArtworkState clone() => SendArtworkState(
        wallet: wallet,
        isScanQR: isScanQR,
        isAddressError: isAddressError,
        isQuantityError: isQuantityError,
        isEstimating: isEstimating,
        isValid: isValid,
        fee: fee,
        address: address,
        exchangeRate: exchangeRate,
        balance: balance,
        quantity: quantity,
        feeOption: feeOption,
        feeOptionValue: feeOptionValue,
      );

  SendArtworkState copyWith({int? quantity, bool? isEstimating, BigInt? fee}) {
    return SendArtworkState(
      wallet: wallet,
      isScanQR: isScanQR,
      isAddressError: isAddressError,
      isQuantityError: isQuantityError,
      isEstimating: isEstimating ?? this.isEstimating,
      isValid: isValid,
      fee: fee ?? this.fee,
      address: address,
      exchangeRate: exchangeRate,
      balance: balance,
      quantity: quantity ?? this.quantity,
      feeOption: feeOption,
      feeOptionValue: feeOptionValue,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SendArtworkState &&
          runtimeType == other.runtimeType &&
          isScanQR == other.isScanQR &&
          isAddressError == other.isAddressError &&
          isQuantityError == other.isQuantityError &&
          isValid == other.isValid &&
          fee == other.fee &&
          address == other.address &&
          balance == other.balance &&
          exchangeRate == other.exchangeRate &&
          isEstimating == other.isEstimating &&
          quantity == other.quantity &&
          feeOption == other.feeOption &&
          feeOptionValue == other.feeOptionValue;

  @override
  int get hashCode =>
      isScanQR.hashCode ^
      isAddressError.hashCode ^
      isQuantityError.hashCode ^
      isValid.hashCode ^
      (fee?.hashCode ?? 0) ^
      (address?.hashCode ?? 0) ^
      balance.hashCode ^
      exchangeRate.hashCode ^
      isEstimating.hashCode ^
      quantity.hashCode ^
      feeOption.hashCode ^
      feeOptionValue.hashCode;
}
