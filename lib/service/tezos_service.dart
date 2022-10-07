//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: implementation_imports

import 'dart:math';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:tezart/src/crypto/crypto.dart' as crypto;
import 'package:tezart/src/crypto/crypto.dart' show Prefixes;
import 'package:tezart/tezart.dart';

abstract class TezosService {
  Future<int> getBalance(String address);

  Future<int> estimateOperationFee(
      String publicKey, List<Operation> operations);

  Future<int> estimateFee(String publicKey, String to, int amount);

  Future<String?> sendOperationTransaction(
      WalletStorage wallet, List<Operation> operations);

  Future<String?> sendTransaction(WalletStorage wallet, String to, int amount);

  Future<String> signMessage(WalletStorage wallet, Uint8List message);

  Future<Operation> getFa2TransferOperation(
      String contract, String from, String to, int tokenId, int quantity);
}

class TezosServiceImpl extends TezosService {
  final TezartClient _tezartClient;

  late final backupTezartClients = [
    TezartClient("https://mainnet.api.tez.ie"),
    TezartClient("https://mainnet.smartpy.io"),
    TezartClient("https://rpc.tzbeta.net"),
    TezartClient("https://mainnet-tezos.giganode.io"),
    TezartClient("https://mainnet.tezos.marigold.dev"),
  ];

  TezosServiceImpl(this._tezartClient);

  @override
  Future<int> getBalance(String address) {
    log.info("TezosService.getBalance: $address");
    return _retryOnNodeError<int>((client) async {
      return client.getBalance(address: address);
    });
  }

  @override
  Future<int> estimateOperationFee(
      String publicKey, List<Operation> operations) async {
    log.info("TezosService.estimateOperationFee");

    return _retryOnNodeError<int>((client) async {
      var operationList = OperationsList(
          publicKey: publicKey,
          rpcInterface: client.rpcInterface);

      for (var element in operations) {
        operationList.appendOperation(element);
      }

      final isReveal =
          await client.isKeyRevealed(publicKey.publicKeyToTezosAddress());
      if (!isReveal) {
        operationList.prependOperation(RevealOperation());
      }

      await operationList.estimate();

      return operationList.operations
          .map((e) => e.totalFee)
          .reduce((value, element) => value + element);
    });
  }

  @override
  Future<String?> sendOperationTransaction(
      WalletStorage wallet, List<Operation> operations) async {
    log.info("TezosService.sendOperationTransaction");

    return _retryOnNodeError<String?>((client) async {
      var operationList = OperationsList(
          publicKey: await wallet.getTezosPublicKey(),
          rpcInterface: client.rpcInterface);

      for (var element in operations) {
        operationList.appendOperation(element);
      }

      final isReveal =
          await client.isKeyRevealed(await wallet.getTezosAddress());
      if (!isReveal) {
        operationList.prependOperation(RevealOperation());
      }

      await operationList
          .execute((forgedHex) => wallet.tezosSignTransaction(forgedHex));

      return operationList.result.id;
    });
  }

  @override
  Future<int> estimateFee(String publicKey, String to, int amount) async {
    log.info("TezosService.estimateFee: $to, $amount");

    return _retryOnNodeError<int>((client) async {
      final operation = await client.transferOperation(
        publicKey: publicKey,
        destination: to,
        amount: amount,
      );
      await operation.estimate();

      return operation.operations
          .map((e) => e.totalFee)
          .reduce((value, element) => value + element);
    });
  }

  @override
  Future<String?> sendTransaction(
      WalletStorage wallet, String to, int amount) async {
    log.info("TezosService.sendTransaction: $to, $amount");
    return _retryOnNodeError<String?>((client) async {
      final operation = await client.transferOperation(
        publicKey: await wallet.getTezosPublicKey(),
        destination: to,
        amount: amount,
      );
      await operation
          .execute((forgedHex) => wallet.tezosSignTransaction(forgedHex));
      return operation.result.id;
    });
  }

  @override
  Future<String> signMessage(WalletStorage wallet, Uint8List message) async {
    final signature = await wallet.tezosSignMessage(message);

    return crypto.encodeWithPrefix(prefix: Prefixes.edsig, bytes: signature);
  }

  @override
  Future<Operation> getFa2TransferOperation(String contract, String from,
      String to, int tokenId, int quantity) async {
    final params = [
      {
        "prim": "Pair",
        "args": [
          {"string": from},
          [
            {
              "args": [
                {"string": to},
                {
                  "prim": "Pair",
                  "args": [
                    {"int": "$tokenId"},
                    {"int": "$quantity"}
                  ]
                }
              ],
              "prim": "Pair"
            }
          ]
        ]
      }
    ];

    return TransactionOperation(
        amount: 0,
        destination: contract,
        entrypoint: "transfer",
        params: params);
  }

  Future<T> _retryOnNodeError<T>(Future<T> Function(TezartClient) func) async {
    try {
      return await func(_tezartClient);
    } on TezartNodeError catch (_) {
      if (Environment.appTestnetConfig) {
        rethrow;
      }

      final random = Random();
      final clientToRetry =
          backupTezartClients[random.nextInt(backupTezartClients.length)];
      return await func(clientToRetry);
    }
  }
}