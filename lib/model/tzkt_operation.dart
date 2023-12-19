//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tzkt_operation.g.dart';

abstract class TZKTTransactionInterface {
  TZKTTokenTransfer? tokenTransfer;

  DateTime getTimeStamp();

  bool isSendNFT(String? currentAddress);

  bool isReceiveNFT(String? currentAddress);

  bool isBoughtNFT(String? currentAddress);

  String totalAmount(String? currentAddress);

  String transactionStatus();

  String transactionTitle(String? currentAddress);

  String transactionTitleDetail(String? currentAddress);

  Widget transactionImage(String? currentAddress);

  String txAmountSign(String? currentAddress);

  int getID();

  String txUSDAmountSign(String? currentAddress);
}

@JsonSerializable()
class TZKTOperation implements TZKTTransactionInterface {
  String type;
  int id;
  int level;
  DateTime timestamp;
  String block;
  String hash;
  int counter;
  TZKTActor? sender;
  TZKTActor? initiator;
  int gasLimit;
  int gasUsed;
  int? storageLimit;
  int? storageUsed;
  int bakerFee;
  int? storageFee;
  int? allocationFee;
  TZKTActor? target;
  int? amount;
  String? status;
  bool? hasInternals;
  TZKTQuote quote;
  TZKTParameter? parameter;

  TZKTOperation({
    required this.type,
    required this.id,
    required this.level,
    required this.timestamp,
    required this.block,
    required this.hash,
    required this.counter,
    required this.gasLimit,
    required this.gasUsed,
    required this.bakerFee,
    required this.quote,
    this.initiator,
    this.sender,
    this.target,
    this.storageLimit,
    this.storageUsed,
    this.storageFee,
    this.allocationFee,
    this.amount,
    this.status,
    this.hasInternals,
    this.parameter,
  });

  factory TZKTOperation.fromJson(Map<String, dynamic> json) =>
      _$TZKTOperationFromJson(json);

  Map<String, dynamic> toJson() => _$TZKTOperationToJson(this);

  @override
  TZKTTokenTransfer? tokenTransfer;

  @override
  DateTime getTimeStamp() => timestamp.toLocal();

  @override
  bool isReceiveNFT(String? currentAddress) {
    currentAddress = currentAddress ?? sender?.address;
    if (currentAddress == null) {
      return false;
    }
    if (tokenTransfer?.to?.address == currentAddress) {
      return true;
    }
    return false;
  }

  @override
  bool isSendNFT(String? currentAddress) {
    currentAddress = currentAddress ?? sender?.address;
    if (currentAddress == null) {
      return false;
    }
    if (tokenTransfer?.from?.address == currentAddress) {
      return true;
    }
    return false;
  }

  @override
  String transactionTitle(String? currentAddress) {
    if (isBoughtNFT(currentAddress)) {
      return 'bought_nft'.tr();
    }
    if (isSendNFT(currentAddress)) {
      return 'sent_nft'.tr();
    }
    if (isReceiveNFT(currentAddress)) {
      return 'received_nft'.tr();
    }
    if (type != 'transaction') {
      return type.capitalize();
    } else if (parameter != null) {
      return parameter!.entrypoint.snakeToCapital();
    } else {
      return sender?.address == currentAddress
          ? 'sent_xtz'.tr()
          : 'received_xtz'.tr();
    }
  }

  @override
  String totalAmount(String? currentAddress) {
    if (isReceiveNFT(currentAddress)) {
      return tokenTransfer!.totalAmount(currentAddress);
    }
    return '${XtzAmountFormatter().format(getTotalAmount(currentAddress))} XTZ';
  }

  String totalXTZAmount(String? currentAddress) =>
      '${XtzAmountFormatter().format(getTotalAmount(currentAddress))} XTZ';

  int getTotalAmount(String? currentAddress) {
    if (sender?.address == currentAddress) {
      return (amount ?? 0) +
          bakerFee +
          (storageFee ?? 0) +
          (allocationFee ?? 0);
    } else {
      return amount ?? 0;
    }
  }

  @override
  Widget transactionImage(String? currentAddress) => SvgPicture.asset(
        'assets/images/tez.svg',
        width: 40,
      );

  @override
  String transactionStatus() {
    if (status == null) {
      return 'pending'.tr();
    } else {
      return status!.capitalize();
    }
  }

  @override
  String txAmountSign(String? currentAddress) {
    String? a = transactionTitle(currentAddress);
    if (a == 'received_nft'.tr() || a == 'received_xtz'.tr()) {
      return '+';
    }
    return '-';
  }

  @override
  String transactionTitleDetail(String? currentAddress) {
    if (isBoughtNFT(currentAddress)) {
      return 'bought_nft'.tr();
    }
    if (isSendNFT(currentAddress)) {
      return 'sent_nft'.tr();
    }
    if (isReceiveNFT(currentAddress)) {
      return 'received_nft'.tr();
    }
    if (parameter != null) {
      return 'sc_interaction'.tr();
    } else if (type != 'transaction') {
      return type.capitalize();
    } else {
      return sender?.address == currentAddress
          ? 'sent_xtz'.tr()
          : 'received_xtz'.tr();
    }
  }

  @override
  int getID() => id;

  @override
  String txUSDAmountSign(String? currentAddress) {
    if (transactionTitle(currentAddress) == 'received_xtz'.tr()) {
      return '+';
    }
    if (sender?.address == currentAddress) {
      return '-';
    }
    return '';
  }

  @override
  bool isBoughtNFT(String? currentAddress) {
    if (isReceiveNFT(currentAddress) &&
        !isSendNFT(currentAddress) &&
        sender?.address == currentAddress) {
      return true;
    }
    return false;
  }
}

@JsonSerializable()
class TZKTTokenTransfer implements TZKTTransactionInterface {
  int id;
  int level;
  DateTime timestamp;
  String? amount;
  TZKTToken? token;
  TZKTActor? from;
  TZKTActor? to;
  int? transactionId;
  int? originationId;
  int? migrationId;
  String? status;

  TZKTTokenTransfer({
    required this.id,
    required this.level,
    required this.timestamp,
    this.amount,
    this.token,
    this.from,
    this.to,
    this.transactionId,
    this.originationId,
    this.migrationId,
    this.status,
  });

  factory TZKTTokenTransfer.fromJson(Map<String, dynamic> json) =>
      _$TZKTTokenTransferFromJson(json);

  Map<String, dynamic> toJson() => _$TZKTTokenTransferToJson(this);

  @override
  TZKTTokenTransfer? tokenTransfer;

  @override
  DateTime getTimeStamp() => timestamp.toLocal();

  @override
  bool isReceiveNFT(String? currentAddress) {
    if (to?.address == currentAddress) {
      return true;
    }
    return false;
  }

  @override
  bool isSendNFT(String? currentAddress) {
    if (from?.address == currentAddress) {
      return true;
    }
    return false;
  }

  @override
  String totalAmount(String? currentAddress) {
    if (amount == null) {
      return '0 Token';
    }
    if (amount == '1' || amount == '0') {
      return '$amount Token';
    }
    try {
      final amountBigInt = BigInt.parse(amount!);
      final amountStr = amountBigInt < BigInt.from(1000000000)
          ? amount
          : amountBigInt.isValidInt
              ? NumberFormat.compact().format(int.parse(amount!))
              : '${amount!.substring(0, amount!.length - 12)}T';
      return '$amountStr Tokens';
    } catch (_) {
      return 'N/A Token';
    }
  }

  @override
  Widget transactionImage(String? currentAddress) =>
      SvgPicture.asset('assets/images/tez.svg', width: 40);

  @override
  String transactionStatus() => status?.tr() ?? 'applied'.tr();

  @override
  String transactionTitle(String? currentAddress) =>
      isSendNFT(currentAddress) ? 'sent_nft'.tr() : 'received_nft'.tr();

  @override
  String txAmountSign(String? currentAddress) {
    String? a = transactionTitle(currentAddress);
    if (a == 'received_nft'.tr() || a == 'received_xtz'.tr()) {
      return '+';
    }
    return '-';
  }

  @override
  String transactionTitleDetail(String? currentAddress) =>
      transactionTitle(currentAddress);

  @override
  int getID() => id;

  @override
  String txUSDAmountSign(String? currentAddress) => '';

  @override
  bool isBoughtNFT(String? currentAddress) => false;
}

@JsonSerializable()
class TZKTToken {
  int id;
  TZKTActor? contract;
  String? tokenId;
  String? standard;
  Map<String, dynamic>? metadata;

  TZKTToken({
    required this.id,
    this.contract,
    this.tokenId,
    this.standard,
    this.metadata,
  });

  factory TZKTToken.fromJson(Map<String, dynamic> json) =>
      _$TZKTTokenFromJson(json);

  Map<String, dynamic> toJson() => _$TZKTTokenToJson(this);
}

@JsonSerializable()
class TZKTActor {
  String address;
  String? alias;

  TZKTActor({required this.address, this.alias});

  factory TZKTActor.fromJson(Map<String, dynamic> json) =>
      _$TZKTActorFromJson(json);

  Map<String, dynamic> toJson() => _$TZKTActorToJson(this);
}

@JsonSerializable()
class TZKTQuote {
  double usd;

  TZKTQuote({required this.usd});

  factory TZKTQuote.fromJson(Map<String, dynamic> json) =>
      _$TZKTQuoteFromJson(json);

  Map<String, dynamic> toJson() => _$TZKTQuoteToJson(this);
}

@JsonSerializable()
class TZKTParameter {
  String entrypoint;
  Object? value;

  TZKTParameter({required this.entrypoint, required this.value});

  factory TZKTParameter.fromJson(Map<String, dynamic> json) =>
      _$TZKTParameterFromJson(json);

  Map<String, dynamic> toJson() => _$TZKTParameterToJson(this);
}
