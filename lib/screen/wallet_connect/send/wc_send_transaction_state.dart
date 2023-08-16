//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/currency_exchange.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/fee_util.dart';
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
  final AppMetadata peerMeta;
  final int requestId;
  final EthereumAddress to;
  final BigInt value;
  final BigInt? gas;
  final String? data;
  final String uuid;
  final int index;
  final bool isWalletConnect2;
  final bool isIRL;
  final String? topic;

  WCSendTransactionSendEvent(
    this.peerMeta,
    this.requestId,
    this.to,
    this.value,
    this.gas,
    this.data,
    this.uuid,
    this.index, {
    required this.isWalletConnect2,
    this.isIRL = false,
    this.topic,
  });
}

class FeeOptionChangedEvent extends WCSendTransactionEvent {
  final FeeOption feeOption;

  FeeOptionChangedEvent(this.feeOption);
}

class WCSendTransactionRejectEvent extends WCSendTransactionEvent {
  final AppMetadata peerMeta;
  final int requestId;
  final String? topic;
  final bool isWalletConnect2;
  final bool isIRL;

  WCSendTransactionRejectEvent(
    this.peerMeta,
    this.requestId, {
    this.topic,
    required this.isWalletConnect2,
    this.isIRL = false,
  });
}

class WCSendTransactionState {
  BigInt? fee;
  BigInt? balance;
  bool isSending = false;
  bool isError = false;
  FeeOption feeOption;
  FeeOptionValue? feeOptionValue;
  CurrencyExchangeRate exchangeRate;

  WCSendTransactionState({
    this.fee,
    this.balance,
    this.isSending = false,
    this.isError = false,
    this.feeOption = DEFAULT_FEE_OPTION,
    this.feeOptionValue,
    this.exchangeRate = const CurrencyExchangeRate(eth: "1.0", xtz: "1.0"),
  });

  WCSendTransactionState clone() => WCSendTransactionState(
        fee: fee,
        balance: balance,
        feeOption: feeOption,
        feeOptionValue: feeOptionValue,
        exchangeRate: exchangeRate,
      );
}
