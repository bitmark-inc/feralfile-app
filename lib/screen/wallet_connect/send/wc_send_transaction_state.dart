//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/currency_exchange.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/fee_util.dart';
import 'package:walletconnect_flutter_v2/apis/core/pairing/utils/pairing_models.dart';
import 'package:web3dart/web3dart.dart';

abstract class WCSendTransactionEvent {}

class WCSendTransactionEstimateEvent extends WCSendTransactionEvent {
  final EthereumAddress address;
  final EtherAmount amount;
  final String data;
  final String uuid;
  final int index;

  WCSendTransactionEstimateEvent(
      this.address, this.amount, this.data, this.uuid, this.index);
}

class WCSendTransactionSendEvent extends WCSendTransactionEvent {
  final PairingMetadata peerMeta;
  final EthereumAddress to;
  final BigInt value;
  final BigInt? gas;
  final String? data;
  final String uuid;
  final int index;
  final bool isIRL;
  final String? topic;

  WCSendTransactionSendEvent(
    this.peerMeta,
    this.to,
    this.value,
    this.gas,
    this.data,
    this.uuid,
    this.index, {
    this.isIRL = false,
    this.topic,
  });
}

class FeeOptionChangedEvent extends WCSendTransactionEvent {
  final FeeOption feeOption;

  FeeOptionChangedEvent(this.feeOption);
}

class WCSendTransactionState {
  BigInt? fee;
  BigInt? balance;
  bool isSending = false;
  bool isError = false;
  FeeOption feeOption;
  FeeOptionValue? feeOptionValue;
  CurrencyExchangeRate? exchangeRate;

  WCSendTransactionState({
    this.fee,
    this.balance,
    this.isSending = false,
    this.isError = false,
    this.feeOption = DEFAULT_FEE_OPTION,
    this.feeOptionValue,
    this.exchangeRate,
  });

  WCSendTransactionState clone() => WCSendTransactionState(
        fee: fee,
        balance: balance,
        feeOption: feeOption,
        feeOptionValue: feeOptionValue,
        exchangeRate: exchangeRate,
      );
}
