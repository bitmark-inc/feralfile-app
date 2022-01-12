import 'dart:typed_data';

import 'package:autonomy_flutter/service/persona_service.dart';
import 'package:flutter/foundation.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:tezart/tezart.dart';
import 'package:tezart/src/crypto/crypto.dart' as crypto;
import 'package:tezart/src/crypto/crypto.dart' show Prefixes;

abstract class TezosService {
  Future<String> getTezosAddress();
  Future<int> getBalance(String address);
  Future<int> estimateFee(String to, int amount);
  Future<String?> sendTransaction(String to, int amount);
}

class TezosServiceImpl extends TezosService {

  final TezartClient _tezartClient;
  final PersonaService _personaService;

  TezosServiceImpl(this._tezartClient, this._personaService);

  @override
  Future<String> getTezosAddress() async {
    final wallet = await _personaService.getActivePersona()?.getTezosWallet();
    if (wallet != null) {
      return wallet.address;
    } else {
      return "";
    }
  }

  @override
  Future<int> getBalance(String address) {
    return _tezartClient.getBalance(address: address);
  }

  @override
  Future<int> estimateFee(String to, int amount) async {
    final keystore = await _getKeystore();
    final operation = await _tezartClient.transferOperation(source: keystore, destination: to, amount: amount, reveal: true);
    await operation.estimate();

    return operation.operations.map((e) => e.fee).reduce((value, element) => value + element);
    //
    // final operationsList = OperationsList(rpcInterface: _tezartClient.rpcInterface, source: keystore);
    // final transactionOperation = TransactionOperation(amount: 1, destination: to);
    //
    // operationsList.appendOperation(transactionOperation);
    // await operationsList.estimate();
    //
    // return operationsList.operations.map((e) => e.fee).reduce((value, element) => value + element);
  }

  @override
  Future<String?> sendTransaction(String to, int amount) async {
    final keystore = await _getKeystore();
    final operation = await _tezartClient.transferOperation(source: keystore, destination: to, amount: amount, reveal: true);
    await operation.execute();

    return operation.result.signature?.edsig;
    //
    // final operationsList = OperationsList(rpcInterface: _tezartClient.rpcInterface, source: keystore);
    // final transactionOperation = TransactionOperation(amount: amount, destination: to);
    //
    // operationsList.appendOperation(transactionOperation);
    // await operationsList.execute();

    // return operationsList.result.signature?.edsig;
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