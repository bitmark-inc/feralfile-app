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
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/ether_amount_ext.dart';
import 'package:autonomy_flutter/util/fee_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:flutter/services.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

const double gWeiFactor = 1000000000;

abstract class EthereumService {
  Future<String> getETHAddress(WalletStorage wallet, int index);

  Future<EtherAmount> getBalance(String address);

  Future<String> signPersonalMessage(
      WalletStorage wallet, int index, Uint8List message);

  Future<String> signMessage(
      WalletStorage wallet, int index, Uint8List message);

  Future<FeeOptionValue> estimateFee(WalletStorage wallet, int index,
      EthereumAddress to, EtherAmount amount, String? data);

  Future<String> sendTransaction(WalletStorage wallet, int index,
      EthereumAddress to, BigInt value, String? data,
      {required FeeOption feeOption});

  Future<String?> getERC721TransferTransactionData(
      EthereumAddress contractAddress,
      EthereumAddress from,
      EthereumAddress to,
      String tokenId,
      {FeeOption? feeOption});

  Future<String?> getERC1155TransferTransactionData(
      EthereumAddress contractAddress,
      EthereumAddress from,
      EthereumAddress to,
      String tokenId,
      int quantity,
      {FeeOption? feeOption});

  Future<BigInt> getERC20TokenBalance(
      EthereumAddress contractAddress, EthereumAddress owner);

  Future<String?> getERC20TransferTransactionData(
      EthereumAddress contractAddress,
      EthereumAddress from,
      EthereumAddress to,
      BigInt quantity,
      {FeeOption? feeOption});

  Future<List<String>> getPublicRecordOwners(BigInt startIndex, BigInt count);

  Future<String> getFeralFileTokenMetadata(
      EthereumAddress contract, Uint8List data);

  Future<FeeOptionValue> getFeeOptionValue();
}

class EthereumServiceImpl extends EthereumService {
  final Web3Client _web3Client;
  final EtherchainApi _etherchainApi;
  final HiveService _hiveService;
  final RemoteConfigService _remoteConfigService;
  final NetworkIssueManager _networkIssueManager;

  EthereumServiceImpl(this._web3Client, this._etherchainApi, this._hiveService,
      this._remoteConfigService, this._networkIssueManager);

  @override
  Future<FeeOptionValue> estimateFee(WalletStorage wallet, int index,
      EthereumAddress to, EtherAmount amount, String? data,
      {FeeOption feeOption = DEFAULT_FEE_OPTION}) async {
    log.info('[EthereumService] estimateFee - to: $to - amount $amount');

    final gasPrice = await getFeeOptionValue();
    final sender =
        EthereumAddress.fromHex(await wallet.getETHEip55Address(index: index));
    final fee = await getEthereumFee(feeOption);

    try {
      BigInt gas = await _web3Client.estimateGas(
        sender: sender,
        to: to,
        value: amount,
        maxFeePerGas: fee.maxFeePerGas,
        maxPriorityFeePerGas: fee.maxPriorityFeePerGas,
        data: (data != null && data.isNotEmpty) ? hexToBytes(data) : null,
      );
      return gasPrice.multipleBy(gas);
    } catch (err) {
      if (data != null && data.isNotEmpty) {
        rethrow;
      } else {
        //Cannot estimate return default value for sending ETH
        return gasPrice.multipleBy(BigInt.from(21000));
      }
    }
  }

  @override
  Future<String> getETHAddress(WalletStorage wallet, int index) async {
    final address = await wallet.getETHAddress(index: index);
    if (address.isEmpty) {
      return '';
    } else {
      log.info(address);
      return EthereumAddress.fromHex(address).hexEip55;
    }
  }

  @override
  Future<EtherAmount> getBalance(String address) async {
    if (address == '') {
      return EtherAmount.zero();
    }

    final ethAddress = EthereumAddress.fromHex(address);
    final amount = await _web3Client.getBalance(ethAddress);
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

  @override
  Future<String> signPersonalMessage(
          WalletStorage wallet, int index, Uint8List message) async =>
      await wallet.ethSignPersonalMessage(message, index: index);

  @override
  Future<String> signMessage(
          WalletStorage wallet, int index, Uint8List message) async =>
      await wallet.ethSignMessage(message, index: index);

  @override
  Future<String> sendTransaction(WalletStorage wallet, int index,
      EthereumAddress to, BigInt value, String? data,
      {required FeeOption feeOption}) async {
    log.info('[EthereumService] sendTransaction - to: $to - amount $value');

    final sender =
        EthereumAddress.fromHex(await wallet.getETHEip55Address(index: index));
    final nonce = await _web3Client.getTransactionCount(sender,
        atBlock: const BlockNum.pending());
    var gasLimit =
        await _estimateGasLimit(sender, to, EtherAmount.inWei(value), data);
    final chainId = Environment.web3ChainId;
    Uint8List signedTransaction;
    final fee = await getEthereumFee(feeOption);

    signedTransaction = await wallet.ethSignTransaction1559(
        nonce: nonce,
        gasLimit: gasLimit,
        maxFeePerGas: fee.maxFeePerGas.getInWei,
        maxPriorityFeePerGas: fee.maxPriorityFeePerGas.getInWei,
        to: to.hexEip55,
        value: value,
        data: data ?? '',
        chainId: chainId,
        index: index);
    final tx = await _networkIssueManager.retryOnConnectIssue<String>(
        () => _web3Client.sendRawTransaction(signedTransaction));

    final deductValue = sender == to ? BigInt.zero : value;
    final deductFee = gasLimit * fee.maxFeePerGas.getInWei;
    final ethPendingAmount = EthereumPendingTxAmount(
        txHash: tx, deductAmount: deductValue + deductFee);
    await _hiveService.saveEthPendingTxAmount(
        ethPendingAmount, sender.hexEip55);
    return tx;
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
  Future<String?> getERC721TransferTransactionData(
      EthereumAddress contractAddress,
      EthereumAddress from,
      EthereumAddress to,
      String tokenId,
      {FeeOption? feeOption}) async {
    final contractJson = await rootBundle.loadString('assets/erc721-abi.json');
    final contract = DeployedContract(
        ContractAbi.fromJson(contractJson, 'ERC721'), contractAddress);
    ContractFunction transferFrom() => contract.function('safeTransferFrom');

    final nonce = await _web3Client.getTransactionCount(from,
        atBlock: const BlockNum.pending());
    Transaction transaction;
    if (feeOption != null) {
      final fee = await getEthereumFee(feeOption);
      transaction = Transaction.callContract(
        contract: contract,
        function: transferFrom(),
        parameters: [from, to, BigInt.parse(tokenId, radix: 10)],
        from: from,
        maxPriorityFeePerGas: fee.maxPriorityFeePerGas,
        maxFeePerGas: fee.maxFeePerGas,
        nonce: nonce,
      );
    } else {
      final gasPrice = await _getGasPrice();
      transaction = Transaction.callContract(
        contract: contract,
        function: transferFrom(),
        parameters: [from, to, BigInt.parse(tokenId, radix: 10)],
        from: from,
        gasPrice: gasPrice,
        nonce: nonce,
      );
    }

    return transaction.data != null ? bytesToHex(transaction.data!) : null;
  }

  @override
  Future<String?> getERC1155TransferTransactionData(
      EthereumAddress contractAddress,
      EthereumAddress from,
      EthereumAddress to,
      String tokenId,
      int quantity,
      {FeeOption? feeOption}) async {
    final contractJson = await rootBundle.loadString('assets/erc1155-abi.json');
    final contract = DeployedContract(
        ContractAbi.fromJson(contractJson, 'ERC1155'), contractAddress);
    ContractFunction transferFrom() =>
        contract.function('safeBatchTransferFrom');

    final nonce = await _web3Client.getTransactionCount(from,
        atBlock: const BlockNum.pending());

    Transaction transaction;
    if (feeOption != null) {
      final fee = await getEthereumFee(feeOption);
      transaction = Transaction.callContract(
        contract: contract,
        function: transferFrom(),
        parameters: [
          from,
          to,
          [BigInt.parse(tokenId, radix: 10)],
          [BigInt.from(quantity)],
          Uint8List(0),
        ],
        from: from,
        maxPriorityFeePerGas: fee.maxPriorityFeePerGas,
        maxFeePerGas: fee.maxFeePerGas,
        nonce: nonce,
      );
    } else {
      final gasPrice = await _getGasPrice();
      transaction = Transaction.callContract(
        contract: contract,
        function: transferFrom(),
        parameters: [
          from,
          to,
          [BigInt.parse(tokenId, radix: 10)],
          [BigInt.from(quantity)],
          Uint8List(0),
        ],
        from: from,
        gasPrice: gasPrice,
        nonce: nonce,
      );
    }

    return transaction.data != null ? bytesToHex(transaction.data!) : null;
  }

  @override
  Future<BigInt> getERC20TokenBalance(
      EthereumAddress contractAddress, EthereumAddress owner) async {
    final contractJson = await rootBundle.loadString('assets/erc20-abi.json');
    final contract = DeployedContract(
        ContractAbi.fromJson(contractJson, 'ERC20'), contractAddress);
    ContractFunction balanceFunction() => contract.function('balanceOf');

    var response = await _web3Client.call(
      contract: contract,
      function: balanceFunction(),
      params: [owner],
    );

    return response.first as BigInt;
  }

  @override
  Future<String?> getERC20TransferTransactionData(
      EthereumAddress contractAddress,
      EthereumAddress from,
      EthereumAddress to,
      BigInt quantity,
      {FeeOption? feeOption}) async {
    final contractJson = await rootBundle.loadString('assets/erc20-abi.json');
    final contract = DeployedContract(
        ContractAbi.fromJson(contractJson, 'ERC20'), contractAddress);
    ContractFunction transferFrom() => contract.function('transfer');

    final nonce = await _web3Client.getTransactionCount(from,
        atBlock: const BlockNum.pending());

    Transaction transaction;
    if (feeOption != null) {
      final fee = await getEthereumFee(feeOption);
      transaction = Transaction.callContract(
        contract: contract,
        function: transferFrom(),
        parameters: [to, quantity],
        from: from,
        maxFeePerGas: fee.maxFeePerGas,
        maxPriorityFeePerGas: fee.maxPriorityFeePerGas,
        nonce: nonce,
      );
    } else {
      final gasPrice = await _getGasPrice();
      transaction = Transaction.callContract(
        contract: contract,
        function: transferFrom(),
        parameters: [to, quantity],
        from: from,
        gasPrice: gasPrice,
        nonce: nonce,
      );
    }

    return transaction.data != null ? bytesToHex(transaction.data!) : null;
  }

  @override
  Future<List<String>> getPublicRecordOwners(
      BigInt startIndex, BigInt count) async {
    try {
      log.info('[EthereumService] getPublicRecordOwners '
          '- startIndex: $startIndex - count: $count');
      final List<String> result = [];
      final config = _remoteConfigService.getConfig<Map<String, dynamic>>(
          ConfigGroup.exhibition, ConfigKey.yokoOnoPublic, {});

      final contractJson =
          await rootBundle.loadString('assets/data-owner-abi.json');
      final ownerDataContractAddress =
          EthereumAddress.fromHex(config['owner_data_contract']);
      final contract = DeployedContract(
          ContractAbi.fromJson(contractJson, 'OwnerData'),
          ownerDataContractAddress);
      ContractFunction getFunction() => contract.function('get');

      final exhibitionContract =
          EthereumAddress.fromHex(config['moma_exhibition_contract']);

      final owners = await _web3Client
          .call(contract: contract, function: getFunction(), params: [
        exhibitionContract,
        BigInt.parse(config['public_token_id']),
        startIndex,
        count,
      ]);
      for (var ownerData in owners[0]) {
        final hash = ownerData[1];
        if (hash == null || hash.isEmpty) {
          result.add('');
          continue;
        }
        final EthereumAddress owner = ownerData[0];
        result.add(owner.hexEip55);
      }
      log.info(
          '[EthereumService] getPublicRecordOwners - result: ${result.length}');
      return result;
    } catch (e) {
      log.info(
          '[EthereumService] getPublicRecordOwners failed - fallback RPC $e');
      return [];
    }
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

  Future<EthereumFee> getEthereumFee(FeeOption feeOption) async {
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

  @override
  Future<FeeOptionValue> getFeeOptionValue() async {
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
