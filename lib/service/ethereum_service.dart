import 'dart:typed_data';

import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/log.dart';
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
}

class EthereumServiceImpl extends EthereumService {
  Web3Client _web3Client;
  ConfigurationService _configurationService;

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
    final gasLimit =
        gas != null ? gas ~/ gasPrice.getInWei : BigInt.from(21000);
    final chainId = _configurationService.getNetwork() == Network.MAINNET ? 1 : 4;

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
}
