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
  final int index;

  GetBalanceEvent(this.wallet, this.index);
}

class AddressChangedEvent extends SendArtworkEvent {
  final String address;
  final int index;

  AddressChangedEvent(this.address, this.index);
}

class QuantityUpdateEvent extends SendArtworkEvent {
  final int quantity;
  final int maxQuantity;
  final int index;

  QuantityUpdateEvent(
      {required this.quantity, required this.maxQuantity, required this.index});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuantityUpdateEvent &&
          runtimeType == other.runtimeType &&
          quantity == other.quantity &&
          maxQuantity == other.maxQuantity &&
          index == other.index;

  @override
  int get hashCode => quantity.hashCode ^ maxQuantity.hashCode ^ index;
}

class EstimateFeeEvent extends SendArtworkEvent {
  final String address;
  final int index;
  final String contractAddress;
  final String tokenId;
  final int quantity;
  final SendArtworkState? newState;

  EstimateFeeEvent(this.address, this.index, this.contractAddress, this.tokenId,
      this.quantity,
      {this.newState});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstimateFeeEvent &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          index == other.index &&
          contractAddress == other.contractAddress &&
          tokenId == other.tokenId &&
          quantity == other.quantity;

  @override
  int get hashCode =>
      address.hashCode ^
      index.hashCode ^
      contractAddress.hashCode ^
      tokenId.hashCode ^
      quantity.hashCode;
}

class FeeOptionChangedEvent extends SendArtworkEvent {
  final FeeOption feeOption;

  FeeOptionChangedEvent(this.feeOption);
}

class SendArtworkState {
  WalletStorage? wallet;
  int? index;

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

  String? domain;

  SendArtworkState(
      {this.wallet,
      this.index,
      this.isScanQR = true,
      this.isAddressError = false,
      this.isQuantityError = false,
      this.isEstimating = false,
      this.isValid = false,
      this.fee,
      this.address,
      this.balance,
      this.exchangeRate = const CurrencyExchangeRate(eth: '1.0', xtz: '1.0'),
      this.quantity = 1,
      this.feeOption = DEFAULT_FEE_OPTION,
      this.feeOptionValue,
      this.domain});

  SendArtworkState clone() => SendArtworkState(
        wallet: wallet,
        index: index,
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
        domain: domain,
      );

  SendArtworkState copyWith({int? quantity, bool? isEstimating, BigInt? fee}) =>
      SendArtworkState(
          wallet: wallet,
          index: index,
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
          domain: domain);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SendArtworkState &&
          index == other.index &&
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
      index.hashCode ^
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
