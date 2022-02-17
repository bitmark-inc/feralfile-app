import 'dart:typed_data';

import 'package:autonomy_flutter/service/persona_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/foundation.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:tezart/src/crypto/crypto.dart' as crypto;
import 'package:tezart/src/crypto/crypto.dart' show Prefixes;
import 'package:tezart/tezart.dart';

abstract class TezosService {
  Future<String> getPublicKey(TezosWallet wallet);

  Future<int> getBalance(String address);

  Future<int> estimateOperationFee(
      TezosWallet wallet, List<TransactionOperation> operation);

  Future<int> estimateFee(TezosWallet wallet, String to, int amount);

  Future<String?> sendOperationTransaction(
      TezosWallet wallet, List<TransactionOperation> operation);

  Future<String?> sendTransaction(TezosWallet wallet, String to, int amount);
}

class TezosServiceImpl extends TezosService {
  final TezartClient _tezartClient;
  final PersonaService _personaService;

  TezosServiceImpl(this._tezartClient, this._personaService);

  @override
  Future<String> getPublicKey(TezosWallet wallet) async {
    return crypto.encodeWithPrefix(
      prefix: Prefixes.edpk,
      bytes: wallet.publicKey,
    );
  }

  @override
  Future<int> getBalance(String address) {
    log.info("TezosService.getBalance: $address");
    return _tezartClient.getBalance(address: address);
  }

  @override
  Future<int> estimateOperationFee(
      TezosWallet wallet, List<TransactionOperation> operations) async {
    log.info("TezosService.estimateOperationFee");
    final keystore = _getKeystore(wallet);

    var operationList = OperationsList(
        source: keystore, rpcInterface: _tezartClient.rpcInterface);

    operations.forEach((element) {
      operationList.appendOperation(element);
    });

    final isReveal = await _tezartClient.isKeyRevealed(keystore.address);
    if (!isReveal) {
      operationList.prependOperation(RevealOperation());
    }

    await operationList.estimate();

    return operationList.operations
        .map((e) => e.fee)
        .reduce((value, element) => value + element);
  }

  @override
  Future<String?> sendOperationTransaction(
      TezosWallet wallet, List<TransactionOperation> operations) async {
    log.info("TezosService.sendOperationTransaction");

    final keystore = _getKeystore(wallet);

    var operationList = OperationsList(
        source: keystore, rpcInterface: _tezartClient.rpcInterface);

    operations.forEach((element) {
      operationList.appendOperation(element);
    });

    final isReveal = await _tezartClient.isKeyRevealed(keystore.address);
    if (!isReveal) {
      operationList.prependOperation(RevealOperation());
    }

    await operationList.execute();

    return operationList.result.signature?.edsig;
  }

  @override
  Future<int> estimateFee(TezosWallet wallet, String to, int amount) async {
    log.info("TezosService.estimateFee: $to, $amount");
    final keystore = _getKeystore(wallet);
    final operation = await _tezartClient.transferOperation(
      source: keystore,
      destination: to,
      amount: amount,
      reveal: true,
      customGasLimit: 10500,
      customStorageLimit: 257,
    );
    await operation.estimate();

    return operation.operations
        .map((e) => e.fee)
        .reduce((value, element) => value + element);
  }

  @override
  Future<String?> sendTransaction(
      TezosWallet wallet, String to, int amount) async {
    log.info("TezosService.sendTransaction: $to, $amount");
    final keystore = _getKeystore(wallet);
    final operation = await _tezartClient.transferOperation(
      source: keystore,
      destination: to,
      amount: amount,
      reveal: true,
      customGasLimit: 10500,
      customStorageLimit: 257,
    );
    await operation.execute();

    return operation.result.signature?.edsig;
  }

  Keystore _getKeystore(TezosWallet wallet) {
    final secretKey = crypto.secretKeyBytesFromSeedBytes(wallet.secretKey);

    final secretString = crypto.encodeWithPrefix(
      prefix: Prefixes.edsk,
      bytes: Uint8List.fromList(secretKey.toList()),
    );

    return Keystore.fromSecretKey(secretString);
  }
}
