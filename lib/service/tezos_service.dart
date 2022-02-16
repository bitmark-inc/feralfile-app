import 'dart:typed_data';

import 'package:autonomy_flutter/service/persona_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/foundation.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:tezart/src/crypto/crypto.dart' as crypto;
import 'package:tezart/src/crypto/crypto.dart' show Prefixes;
import 'package:tezart/tezart.dart';

abstract class TezosService {
  Future<String> getTezosAddress();

  Future<String> getPublicKey();

  Future<int> getBalance(String address);

  Future<int> estimateOperationFee(List<TransactionOperation> operation);

  Future<int> estimateFee(String to, int amount);

  Future<String?> sendOperationTransaction(
      List<TransactionOperation> operation);

  Future<String?> sendTransaction(String to, int amount);
}

class TezosServiceImpl extends TezosService {
  final TezartClient _tezartClient;
  final PersonaService _personaService;

  TezosServiceImpl(this._tezartClient, this._personaService);

  @override
  Future<String> getTezosAddress() async {
    log.info("TezosService.getTezosAddress");
    final wallet = await _personaService.getActivePersona()?.getTezosWallet();
    if (wallet != null) {
      log.info("got the tezos address: ${wallet.address}");
      return wallet.address;
    } else {
      log.warning("empty tezos wallet");
      return "";
    }
  }

  @override
  Future<String> getPublicKey() async {
    final wallet = await _personaService.getActivePersona()?.getTezosWallet();
    if (wallet != null) {
      return crypto.encodeWithPrefix(
        prefix: Prefixes.edpk,
        bytes: wallet.publicKey,
      );
    } else {
      return "";
    }
  }

  @override
  Future<int> getBalance(String address) {
    log.info("TezosService.getBalance: $address");
    return _tezartClient.getBalance(address: address);
  }

  @override
  Future<int> estimateOperationFee(
      List<TransactionOperation> operations) async {
    log.info("TezosService.estimateOperationFee");

    final keystore = await _getKeystore();

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
      List<TransactionOperation> operations) async {
    log.info("TezosService.sendOperationTransaction");

    final keystore = await _getKeystore();

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
  Future<int> estimateFee(String to, int amount) async {
    log.info("TezosService.estimateFee: $to, $amount");
    final keystore = await _getKeystore();
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
  Future<String?> sendTransaction(String to, int amount) async {
    log.info("TezosService.sendTransaction: $to, $amount");
    final keystore = await _getKeystore();
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

  Future<Keystore> _getKeystore() async {
    final wallet = await _personaService.getActivePersona()?.getTezosWallet();
    assert(wallet != null);

    return compute(_parseSecretKey, wallet!);
  }

  Keystore _parseSecretKey(TezosWallet wallet) {
    final secretKey = crypto.secretKeyBytesFromSeedBytes(wallet.secretKey);

    final secretString = crypto.encodeWithPrefix(
      prefix: Prefixes.edsk,
      bytes: Uint8List.fromList(secretKey.toList()),
    );

    return Keystore.fromSecretKey(secretString);
  }
}
