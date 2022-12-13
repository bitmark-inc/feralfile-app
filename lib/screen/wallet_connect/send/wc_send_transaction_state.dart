//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/fee_util.dart';
import 'package:wallet_connect/models/wc_peer_meta.dart';
import 'package:web3dart/web3dart.dart';

abstract class WCSendTransactionEvent {}

class WCSendTransactionEstimateEvent extends WCSendTransactionEvent {
  final EthereumAddress address;
  final EtherAmount amount;
  final String data;
  final String uuid;

  WCSendTransactionEstimateEvent(
      this.address, this.amount, this.data, this.uuid);
}

class WCSendTransactionSendEvent extends WCSendTransactionEvent {
  final WCPeerMeta peerMeta;
  final int requestId;
  final EthereumAddress to;
  final BigInt value;
  final BigInt? gas;
  final String? data;
  final String uuid;
  final bool isWalletConnect2;
  final String? topic;

  WCSendTransactionSendEvent(
    this.peerMeta,
    this.requestId,
    this.to,
    this.value,
    this.gas,
    this.data,
    this.uuid, {
    required this.isWalletConnect2,
    this.topic,
  });
}

class FeeOptionChangedEvent extends WCSendTransactionEvent {
  final FeeOption feeOption;

  FeeOptionChangedEvent(this.feeOption);
}

class WCSendTransactionRejectEvent extends WCSendTransactionEvent {
  final WCPeerMeta peerMeta;
  final int requestId;
  final String? topic;
  final bool isWalletConnect2;

  WCSendTransactionRejectEvent(
    this.peerMeta,
    this.requestId, {
    this.topic,
    required this.isWalletConnect2,
  });
}

class WCSendTransactionState {
  BigInt? fee;
  BigInt? balance;
  bool isSending = false;
  bool isError = false;
  FeeOption feeOption;
  FeeOptionValue? feeOptionValue;

  WCSendTransactionState({
    this.fee,
    this.balance,
    this.isSending = false,
    this.isError = false,
    this.feeOption = DEFAULT_FEE_OPTION,
    this.feeOptionValue,
  });

  WCSendTransactionState clone() => WCSendTransactionState(
        fee: fee,
        balance: balance,
        isSending: isSending,
        isError: isError,
        feeOption: feeOption,
        feeOptionValue: feeOptionValue,
      );
}
