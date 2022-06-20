//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:math';
import 'dart:typed_data';

import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:tezart/src/crypto/crypto.dart' as crypto;
import 'package:tezart/src/crypto/crypto.dart' show Prefixes;
import 'package:tezart/tezart.dart';

abstract class TezosService {
  Future<String> getPublicKey(TezosWallet wallet);

  Future<int> getBalance(String address);

  Future<int> estimateOperationFee(
      TezosWallet wallet, List<Operation> operation);

  Future<int> estimateFee(TezosWallet wallet, String to, int amount);

  Future<String?> sendOperationTransaction(
      TezosWallet wallet, List<Operation> operation);

  Future<String?> sendTransaction(TezosWallet wallet, String to, int amount);

  Future<String> signMessage(TezosWallet wallet, Uint8List message);
}

class TezosServiceImpl extends TezosService {
  final TezartClient _tezartClient;
  final ConfigurationService _configurationService;

  late final backupTezartClients = [
    TezartClient("https://mainnet.api.tez.ie"),
    TezartClient("https://mainnet.smartpy.io"),
    TezartClient("https://rpc.tzbeta.net"),
    TezartClient("https://mainnet-tezos.giganode.io"),
    TezartClient("https://mainnet.tezos.marigold.dev"),
  ];

  TezosServiceImpl(this._tezartClient, this._configurationService);

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
    return _retryOnNodeError<int>((client) async {
      return client.getBalance(address: address);
    });
  }

  @override
  Future<int> estimateOperationFee(
      TezosWallet wallet, List<Operation> operations) async {
    log.info("TezosService.estimateOperationFee");

    return _retryOnNodeError<int>((client) async {
      final keystore = _getKeystore(wallet);

      var operationList = OperationsList(
          source: keystore, rpcInterface: client.rpcInterface);

      operations.forEach((element) {
        operationList.appendOperation(element);
      });

      final isReveal = await client.isKeyRevealed(keystore.address);
      if (!isReveal) {
        operationList.prependOperation(RevealOperation());
      }

      await operationList.estimate();

      return operationList.operations
          .map((e) => e.fee)
          .reduce((value, element) => value + element);
    });
  }

  @override
  Future<String?> sendOperationTransaction(
      TezosWallet wallet, List<Operation> operations) async {
    log.info("TezosService.sendOperationTransaction");

    return _retryOnNodeError<String?>((client) async {
      final keystore = _getKeystore(wallet);

      var operationList = OperationsList(
          source: keystore, rpcInterface: client.rpcInterface);

      operations.forEach((element) {
        operationList.appendOperation(element);
      });

      final isReveal = await client.isKeyRevealed(keystore.address);
      if (!isReveal) {
        operationList.prependOperation(RevealOperation());
      }

      await operationList.execute();

      return operationList.result.id;
    });
  }

  @override
  Future<int> estimateFee(TezosWallet wallet, String to, int amount) async {
    log.info("TezosService.estimateFee: $to, $amount");

    return _retryOnNodeError<int>((client) async {
      final keystore = _getKeystore(wallet);
      final operation = await client.transferOperation(
        source: keystore,
        destination: to,
        amount: amount,
        reveal: true,
      );
      await operation.estimate();

      return operation.operations
          .map((e) => e.fee)
          .reduce((value, element) => value + element);
    });
  }

  @override
  Future<String?> sendTransaction(
      TezosWallet wallet, String to, int amount) async {
    log.info("TezosService.sendTransaction: $to, $amount");
    return _retryOnNodeError<String?>((client) async {
      final keystore = _getKeystore(wallet);
      final operation = await client.transferOperation(
        source: keystore,
        destination: to,
        amount: amount,
        reveal: true,
      );
      await operation.execute();

      return operation.result.id;
    });
  }

  @override
  Future<String> signMessage(TezosWallet wallet, Uint8List message) async {
    final keystore = _getKeystore(wallet);

    final signature = keystore.signBytes(message);

    return signature.edsig;
  }

  Keystore _getKeystore(TezosWallet wallet) {
    final secretKey = crypto.secretKeyBytesFromSeedBytes(wallet.secretKey);

    final secretString = crypto.encodeWithPrefix(
      prefix: Prefixes.edsk,
      bytes: Uint8List.fromList(secretKey.toList()),
    );

    return Keystore.fromSecretKey(secretString);
  }

  Future<T> _retryOnNodeError<T>(Future<T> Function(TezartClient) func) async {
    try {
      return await func(_tezartClient);
    } on TezartNodeError catch (e) {
      if (_configurationService.getNetwork() == Network.TESTNET) {
        throw e;
      }

      final _random = new Random();
      final clientToRetry = backupTezartClients[_random.nextInt(backupTezartClients.length)];
      return await func(clientToRetry);
    }
  }
}
