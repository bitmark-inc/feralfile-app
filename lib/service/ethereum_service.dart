//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/gateway/etherchain_api.dart';
import 'package:autonomy_flutter/model/eth_pending_tx_amount.dart';
import 'package:autonomy_flutter/service/hive_service.dart';
import 'package:autonomy_flutter/service/network_issue_manager.dart';
import 'package:autonomy_flutter/util/ether_amount_ext.dart';
import 'package:autonomy_flutter/util/fee_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

const double gWeiFactor = 1000000000;

abstract class EthereumService {
  Future<EtherAmount> getBalance(String address, {bool doRetry = false});

  Future<String> getFeralFileTokenMetadata(
      EthereumAddress contract, Uint8List data);
}

class EthereumServiceImpl extends EthereumService {
  final Web3Client _web3Client;
  final EtherchainApi _etherchainApi;
  final HiveService _hiveService;
  final NetworkIssueManager _networkIssueManager;

  EthereumServiceImpl(this._web3Client, this._etherchainApi, this._hiveService,
      this._networkIssueManager);

  @override
  Future<EtherAmount> getBalance(String address, {bool doRetry = false}) async {
    if (address == '') {
      return EtherAmount.zero();
    }

    final ethAddress = EthereumAddress.fromHex(address);
    final amount = await _networkIssueManager.retryOnConnectIssueTx(
        () => _web3Client.getBalance(ethAddress),
        maxRetries: doRetry ? NetworkIssueManager.maxRetries : 0);
    final tx = await _hiveService.getEthPendingTxAmounts(address);
    final List<EthereumPendingTxAmount> pendingTx = [];
    for (final element in tx) {
      final receipt = await _getReceipt(element.txHash);
      if (receipt != null) {
        unawaited(
            _hiveService.deleteEthPendingTxAmount(element.txHash, address));
      } else {
        pendingTx.add(element);
      }
    }
    final pendingAmount = pendingTx.fold<BigInt>(BigInt.zero,
        (previousValue, element) => previousValue + element.getDeductAmount);
    log.info('[EthereumService] getBalance - amount :$amount - '
        'pending :$pendingAmount');

    return amount - EtherAmount.inWei(pendingAmount);
  }

  Future<TransactionReceipt?> _getReceipt(String txHash) async {
    try {
      final receipt = await _web3Client.getTransactionReceipt(txHash);
      if (receipt != null) {
        log.info('[EthereumService] _getReceipt - receipt: ${receipt.status}');
        return receipt;
      }
    } catch (_) {
      log.info('[EthereumService] _getReceipt -error');
    }
    return null;
  }

  @override
  Future<String> getFeralFileTokenMetadata(
      EthereumAddress contract, Uint8List data) async {
    final metadata = await _web3Client.callRaw(contract: contract, data: data);

    final List<FunctionParameter> outputs = [
      const FunctionParameter('string', StringType())
    ];

    final tuple = TupleType(outputs.map((p) => p.type).toList());
    final buffer = hexToBytes(metadata).buffer;

    final parsedData = tuple.decode(buffer, 0);
    return parsedData.data.isNotEmpty ? parsedData.data.first : '';
  }

  Future<BigInt> _estimateGasLimit(EthereumAddress sender, EthereumAddress to,
      EtherAmount amount, String? transactionData) async {
    try {
      BigInt gas = await _web3Client.estimateGas(
        sender: sender,
        to: to,
        value: amount,
        data: transactionData != null ? hexToBytes(transactionData) : null,
      );
      return gas;
    } catch (err) {
      //Cannot estimate return default value
      if (transactionData != null && transactionData.isNotEmpty) {
        return BigInt.from(200000);
      } else {
        return BigInt.from(21000);
      }
    }
  }

  Future<EtherAmount> _getGasPrice() async {
    if (Environment.appTestnetConfig) {
      return await _web3Client.getGasPrice();
    }

    int? gasPrice;
    try {
      gasPrice = (await _etherchainApi.getGasPrice()).data.fast;
    } catch (e) {
      log.info('[EthereumService] getGasPrice failed - fallback RPC $e');
      gasPrice = null;
    }

    if (gasPrice != null) {
      return EtherAmount.inWei(BigInt.from(gasPrice));
    } else {
      return await _web3Client.getGasPrice();
    }
  }

  Future<EthereumFee> _getEthereumFee(FeeOption feeOption) async {
    final baseFee = await _getBaseFee();
    final priorityFee = feeOption.getEthereumPriorityFee;
    final buffer = BigInt.from(baseFee / BigInt.from(8));
    return EthereumFee(
        maxPriorityFeePerGas:
            EtherAmount.fromBigInt(EtherUnit.wei, priorityFee),
        maxFeePerGas: EtherAmount.fromBigInt(
            EtherUnit.wei, baseFee + priorityFee + buffer));
  }

  Future<BigInt> _getBaseFee() async {
    try {
      final blockInfo = await _web3Client.getBlockInformation();
      return blockInfo.baseFeePerGas!.getInWei;
    } catch (e) {
      log.info('[EthereumService] getBaseFee failed - fallback RPC $e');
      return BigInt.from(40000000000);
    }
  }

  Future<FeeOptionValue> _getFeeOptionValue() async {
    final baseFee = await _getBaseFee();
    final buffer = BigInt.from(baseFee / BigInt.from(8));
    return FeeOptionValue(
        baseFee + buffer + FeeOption.LOW.getEthereumPriorityFee,
        baseFee + buffer + FeeOption.MEDIUM.getEthereumPriorityFee,
        baseFee + buffer + FeeOption.HIGH.getEthereumPriorityFee);
  }
}

class EthereumFee {
  final EtherAmount maxPriorityFeePerGas;
  final EtherAmount maxFeePerGas;

  EthereumFee({required this.maxPriorityFeePerGas, required this.maxFeePerGas});
}
