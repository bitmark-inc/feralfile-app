//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//


import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/gateway/etherchain_api.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/services.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

const double gWeiFactor = 1000000000;
abstract class EthereumService {
  Future<String> getETHAddress(WalletStorage wallet);

  Future<EtherAmount> getBalance(String address);

  Future<String> signPersonalMessage(WalletStorage wallet, Uint8List message);

  Future<String> signMessage(WalletStorage wallet, Uint8List message);

  Future<BigInt> estimateFee(WalletStorage wallet, EthereumAddress to,
      EtherAmount amount, String? data);

  Future<String> sendTransaction(
      WalletStorage wallet, EthereumAddress to, BigInt value, String? data, {FeeOption feeOption = FeeOption.LOW});

  Future<String?> getERC721TransferTransactionData(
      EthereumAddress contractAddress,
      EthereumAddress from,
      EthereumAddress to,
      String tokenId,
      {FeeOption feeOption = FeeOption.LOW});

  Future<String?> getERC1155TransferTransactionData(
      EthereumAddress contractAddress,
      EthereumAddress from,
      EthereumAddress to,
      String tokenId,
      int quantity,
      {FeeOption feeOption = FeeOption.LOW});

  Future<BigInt> getERC20TokenBalance(
      EthereumAddress contractAddress, EthereumAddress owner);

  Future<String?> getERC20TransferTransactionData(
      EthereumAddress contractAddress,
      EthereumAddress from,
      EthereumAddress to,
      BigInt quantity,
      {FeeOption feeOption = FeeOption.LOW});

  Future<String> getFeralFileTokenMetadata(
      EthereumAddress contract, Uint8List data);

  Future<EtherAmount> getPriorityFeePerGas(FeeOption feeOption);

  Future<EtherAmount> getMaxPriorityFeePerGas({required EtherAmount priorityFee});
}

class EthereumServiceImpl extends EthereumService {
  final Web3Client _web3Client;
  final EtherchainApi _etherchainApi;

  EthereumServiceImpl(this._web3Client, this._etherchainApi);

  @override
  Future<BigInt> estimateFee(WalletStorage wallet, EthereumAddress to,
      EtherAmount amount, String? data) async {
    log.info("[EthereumService] estimateFee - to: $to - amount $amount");

    final gasPrice = await _getGasPrice();
    final sender = EthereumAddress.fromHex(await wallet.getETHAddress());

    try {
      BigInt gas = await _web3Client.estimateGas(
        sender: sender,
        to: to,
        value: amount,
        gasPrice: gasPrice,
        data: data != null ? hexToBytes(data) : null,
      );
      return gas * gasPrice.getInWei;
    } catch (err) {
      //Cannot estimate return default value
      if (data != null && data.isNotEmpty) {
        return BigInt.from(100000) * gasPrice.getInWei;
      } else {
        return BigInt.from(21000) * gasPrice.getInWei;
      }
    }
  }

  @override
  Future<String> getETHAddress(WalletStorage wallet) async {
    final address = await wallet.getETHAddress();
    if (address.isEmpty) {
      return "";
    } else {
      log.info(address);
      return EthereumAddress.fromHex(address).hexEip55;
    }
  }

  @override
  Future<EtherAmount> getBalance(String address) async {
    if (address == "") return EtherAmount.zero();

    final ethAddress = EthereumAddress.fromHex(address);
    return await _web3Client.getBalance(ethAddress);
  }

  @override
  Future<String> signPersonalMessage(
      WalletStorage wallet, Uint8List message) async {
    return await wallet.ethSignPersonalMessage(message);
  }

  @override
  Future<String> signMessage(WalletStorage wallet, Uint8List message) async {
    return await wallet.ethSignMessage(message);
  }

  @override
  Future<String> sendTransaction(WalletStorage wallet, EthereumAddress to,
      BigInt value, String? data, {FeeOption feeOption = FeeOption.LOW}) async {
    log.info("[EthereumService] sendTransaction - to: $to - amount $value");

    final sender = EthereumAddress.fromHex(await wallet.getETHAddress());
    final nonce = await _web3Client.getTransactionCount(sender);
    var gasLimit =
        (await _estimateGasLimit(sender, to, EtherAmount.inWei(value), data));
    final chainId = Environment.web3ChainId;
    final maxPriorityFeePerGas = await getPriorityFeePerGas(feeOption);
    final maxFeePerGas = await getMaxPriorityFeePerGas(priorityFee: maxPriorityFeePerGas);

    final signedTransaction = await wallet.ethSignTransaction1559(
        nonce: nonce,
        //gasPrice: gasPrice.getInWei,
        gasLimit: gasLimit,
        maxFeePerGas: maxFeePerGas.getInWei,
        maxPriorityFeePerGas: maxPriorityFeePerGas.getInWei,
        to: to.hexEip55,
        value: value,
        data: data ?? "",
        chainId: chainId);

    return _web3Client.sendRawTransaction(signedTransaction);
  }

  @override
  Future<String?> getERC721TransferTransactionData(
      EthereumAddress contractAddress,
      EthereumAddress from,
      EthereumAddress to,
      String tokenId, {FeeOption feeOption = FeeOption.LOW}) async {
    final contractJson = await rootBundle.loadString('assets/erc721-abi.json');
    final contract = DeployedContract(
        ContractAbi.fromJson(contractJson, "ERC721"), contractAddress);
    ContractFunction transferFrom() => contract.function("safeTransferFrom");

    final nonce = await _web3Client.getTransactionCount(from);
    final maxPriorityFeePerGas = await getPriorityFeePerGas(feeOption);
    final maxFeePerGas = await getMaxPriorityFeePerGas(priorityFee: maxPriorityFeePerGas);

    final transaction = Transaction.callContract(
      contract: contract,
      function: transferFrom(),
      parameters: [from, to, BigInt.parse(tokenId, radix: 10)],
      from: from,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
      maxFeePerGas: maxFeePerGas,
      nonce: nonce,
    );

    return transaction.data != null ? bytesToHex(transaction.data!) : null;
  }

  @override
  Future<String?> getERC1155TransferTransactionData(
      EthereumAddress contractAddress,
      EthereumAddress from,
      EthereumAddress to,
      String tokenId,
      int quantity, {FeeOption feeOption = FeeOption.LOW}) async {
    final contractJson = await rootBundle.loadString('assets/erc1155-abi.json');
    final contract = DeployedContract(
        ContractAbi.fromJson(contractJson, "ERC1155"), contractAddress);
    ContractFunction transferFrom() =>
        contract.function("safeBatchTransferFrom");

    final nonce = await _web3Client.getTransactionCount(from);
    final maxPriorityFeePerGas = await getPriorityFeePerGas(feeOption);
    final maxFeePerGas = await getMaxPriorityFeePerGas(priorityFee: maxPriorityFeePerGas);

    final transaction = Transaction.callContract(
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
      maxPriorityFeePerGas: maxPriorityFeePerGas,
      maxFeePerGas: maxFeePerGas,
      nonce: nonce,
    );

    return transaction.data != null ? bytesToHex(transaction.data!) : null;
  }

  @override
  Future<BigInt> getERC20TokenBalance(
      EthereumAddress contractAddress, EthereumAddress owner) async {
    final contractJson = await rootBundle.loadString('assets/erc20-abi.json');
    final contract = DeployedContract(
        ContractAbi.fromJson(contractJson, "ERC20"), contractAddress);
    ContractFunction balanceFunction() => contract.function("balanceOf");

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
      {FeeOption feeOption = FeeOption.LOW}) async {
    final contractJson = await rootBundle.loadString('assets/erc20-abi.json');
    final contract = DeployedContract(
        ContractAbi.fromJson(contractJson, "ERC20"), contractAddress);
    ContractFunction transferFrom() => contract.function("transfer");

    final nonce = await _web3Client.getTransactionCount(from);
    final maxPriorityFeePerGas = await getPriorityFeePerGas(feeOption);
    final maxFeePerGas = await getMaxPriorityFeePerGas(priorityFee: maxPriorityFeePerGas);

    final transaction = Transaction.callContract(
      contract: contract,
      function: transferFrom(),
      parameters: [to, quantity],
      from: from,
      maxFeePerGas: maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
      nonce: nonce,
    );

    return transaction.data != null ? bytesToHex(transaction.data!) : null;
  }

  @override
  Future<String> getFeralFileTokenMetadata(
      EthereumAddress contract, Uint8List data) async {
    final metadata = await _web3Client.callRaw(contract: contract, data: data);

    final List<FunctionParameter> outputs = [
      const FunctionParameter("string", StringType())
    ];

    final tuple = TupleType(outputs.map((p) => p.type).toList());
    final buffer = hexToBytes(metadata).buffer;

    final parsedData = tuple.decode(buffer, 0);
    return parsedData.data.isNotEmpty ? parsedData.data.first : "";
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
      log.info("[EthereumService] getGasPrice failed - fallback RPC $e");
      gasPrice = null;
    }

    if (gasPrice != null) {
      return EtherAmount.inWei(BigInt.from(gasPrice));
    } else {
      return await _web3Client.getGasPrice();
    }
  }

  @override
  Future<EtherAmount> getPriorityFeePerGas(FeeOption feeOption) async {
    final gasPrice = await _etherchainApi.getGasPriceOracle();
    switch (feeOption) {
      case FeeOption.LOW:
        return EtherAmount.fromUnitAndValue(EtherUnit.wei, BigInt.from(gasPrice.safeLow * gWeiFactor));
      case FeeOption.MEDIUM:
        return EtherAmount.fromUnitAndValue(EtherUnit.wei, BigInt.from(gasPrice.fast * gWeiFactor));
      case FeeOption.HIGH:
        return EtherAmount.fromUnitAndValue(EtherUnit.wei, BigInt.from(gasPrice.fastest * gWeiFactor));
    }
  }

  @override
  Future<EtherAmount> getMaxPriorityFeePerGas({required EtherAmount priorityFee}) async {
    final blockInfo = await _web3Client.getBlockInformation();
    final baseFee = blockInfo.baseFeePerGas;
    if (baseFee != null) {
      return EtherAmount.fromUnitAndValue(EtherUnit.wei, baseFee.getInWei + priorityFee.getInWei);
    } else {
      return EtherAmount.fromUnitAndValue(EtherUnit.wei, BigInt.from(15000000000) + priorityFee.getInWei);
    }
  }
}

enum FeeOption {
  LOW,
  MEDIUM,
  HIGH,
}
