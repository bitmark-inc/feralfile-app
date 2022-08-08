//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:typed_data';

import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/services.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

abstract class EthereumService {
  Future<String> getETHAddress(WalletStorage wallet);

  Future<EtherAmount> getBalance(String address);

  Future<String> signPersonalMessage(WalletStorage wallet, Uint8List message);

  Future<BigInt> estimateFee(WalletStorage wallet, EthereumAddress to,
      EtherAmount amount, String? data);

  Future<String> sendTransaction(WalletStorage wallet, EthereumAddress to,
      BigInt value, BigInt? gas, String? data);

  Future<String?> getERC721TransferTransactionData(
      EthereumAddress contractAddress,
      EthereumAddress from,
      EthereumAddress to,
      String tokenId);
}

class EthereumServiceImpl extends EthereumService {
  final Web3Client _web3Client;
  final ConfigurationService _configurationService;

  EthereumServiceImpl(this._web3Client, this._configurationService);

  @override
  Future<BigInt> estimateFee(WalletStorage wallet, EthereumAddress to,
      EtherAmount amount, String? data) async {
    final gasPrice = await _web3Client.getGasPrice();
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
      return BigInt.from(21000) * gasPrice.getInWei;
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
    return await wallet.signPersonalMessage(message);
  }

  @override
  Future<String> sendTransaction(WalletStorage wallet, EthereumAddress to,
      BigInt value, BigInt? gas, String? data) async {
    final sender = EthereumAddress.fromHex(await wallet.getETHAddress());
    final nonce = await _web3Client.getTransactionCount(sender);
    final gasPrice = await _web3Client.getGasPrice();
    var gasLimit = gas != null ? gas ~/ gasPrice.getInWei : null;
    gasLimit ??=
        (await estimateFee(wallet, to, EtherAmount.inWei(value), data)) ~/
            gasPrice.getInWei;
    final chainId =
        _configurationService.getNetwork() == Network.MAINNET ? 1 : 4;

    final signedTransaction = await wallet.signTransaction(
        nonce: nonce,
        gasPrice: gasPrice.getInWei,
        gasLimit: gasLimit,
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
      String tokenId) async {
    final contractJson = await rootBundle.loadString('assets/erc721-abi.json');
    final contract = DeployedContract(
        ContractAbi.fromJson(contractJson, "ERC721"), contractAddress);
    ContractFunction _transferFrom() => contract.function("transferFrom");

    final nonce = await _web3Client.getTransactionCount(from);
    final gasPrice = await _web3Client.getGasPrice();

    final transaction = Transaction.callContract(
      contract: contract,
      function: _transferFrom(),
      parameters: [from, to, BigInt.parse(tokenId, radix: 10)],
      from: from,
      gasPrice: gasPrice,
      nonce: nonce,
    );

    return transaction.data != null ? bytesToHex(transaction.data!) : null;
  }
}
