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
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/network_issue_manager.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:tezart/src/crypto/crypto.dart' as crypto;
import 'package:tezart/src/crypto/crypto.dart' show Prefixes;
import 'package:tezart/tezart.dart';

const baseOperationCustomFeeLow = 100;
const baseOperationCustomFeeMedium = 150;
const baseOperationCustomFeeHigh = 200;

abstract class TezosService {
  Future<int> getBalance(String address, {bool doRetry = false});

  Future<int> estimateOperationFee(String publicKey, List<Operation> operations,
      {int? baseOperationCustomFee});

  Future<int> estimateFee(String publicKey, String to, int amount,
      {int? baseOperationCustomFee});

  Future<String?> sendOperationTransaction(
      WalletStorage wallet, int index, List<Operation> operations,
      {int? baseOperationCustomFee});

  Future<String?> sendTransaction(
      WalletStorage wallet, int index, String to, int amount,
      {int? baseOperationCustomFee});

  Future<String> signMessage(
      WalletStorage wallet, int index, Uint8List message);

  Future<Operation> getFa2TransferOperation(
      String contract, String from, String to, String tokenId, int quantity);
}

class TezosServiceImpl extends TezosService {
  TezartClient get _tezartClient => _getClient();
  final NetworkIssueManager _networkIssueManager;

  TezosServiceImpl(this._networkIssueManager);

  String _nodeUrl = '';

  TezartClient _getClient() {
    if (Environment.appTestnetConfig) {
      return TezartClient(Environment.tezosNodeClientTestnetURL);
    }
    if (_nodeUrl.isEmpty) {
      _changeNode();
    }
    return TezartClient(_nodeUrl);
  }

  void _changeNode() {
    final publicTezosNodes = injector<RemoteConfigService>()
        .toList()
      ..remove(_nodeUrl);
    if (publicTezosNodes.isEmpty) {
      return;
    }
    _nodeUrl = publicTezosNodes[Random().nextInt(publicTezosNodes.length)];
  }

  @override
  Future<int> getBalance(String address, {bool doRetry = false}) {
    log.info('TezosService.getBalance: $address');
    return _retryOnError<int>(
        (client) async => client.getBalance(address: address),
        doRetry: doRetry);
  }

  @override
  Future<int> estimateOperationFee(String publicKey, List<Operation> operations,
      {int? baseOperationCustomFee}) async {
    log.info('TezosService.estimateOperationFee');

    return _retryOnError<int>((client) async {
      var operationList = OperationsList(
          publicKey: publicKey, rpcInterface: client.rpcInterface);

      for (var element in operations) {
        operationList.appendOperation(element);
      }

      final isReveal =
          await client.isKeyRevealed(publicKey.publicKeyToTezosAddress());
      if (!isReveal) {
        operationList.prependOperation(RevealOperation());
      }

      log.info('TezosService.estimateOperationFee: '
          '${operationList.operations.map((e) => e.toJson()).toList()}');

      await operationList.estimate(
          baseOperationCustomFee: baseOperationCustomFee);

      return operationList.operations
          .map((e) => e.totalFee)
          .reduce((value, element) => value + element);
    });
  }

  @override
  Future<String?> sendOperationTransaction(
      WalletStorage wallet, int index, List<Operation> operations,
      {int? baseOperationCustomFee}) async {
    log.info('TezosService.sendOperationTransaction');
    return _retryOnError<String?>((client) async {
      var operationList = OperationsList(
          publicKey: await wallet.getTezosPublicKey(index: index),
          rpcInterface: client.rpcInterface);

      for (var element in operations) {
        operationList.appendOperation(element);
      }

      final isReveal = await client
          .isKeyRevealed(await wallet.getTezosAddress(index: index));
      if (!isReveal) {
        operationList.prependOperation(RevealOperation());
      }

      await operationList.execute(
          (forgedHex) => wallet.tezosSignTransaction(forgedHex, index: index),
          baseOperationCustomFee: baseOperationCustomFee);

      log.info('TezosService.sendOperationTransaction:'
          ' ${operationList.result.id}');
      return operationList.result.id;
    });
  }

  @override
  Future<int> estimateFee(String publicKey, String to, int amount,
      {int? baseOperationCustomFee}) async {
    log.info('TezosService.estimateFee: $to, $amount');
    return _retryOnError<int>((client) async {
      final operation = await client.transferOperation(
        publicKey: publicKey,
        destination: to,
        amount: amount,
      );
      await operation.estimate(baseOperationCustomFee: baseOperationCustomFee);

      return operation.operations
          .map((e) => e.totalFee)
          .reduce((value, element) => value + element);
    });
  }

  @override
  Future<String?> sendTransaction(
      WalletStorage wallet, int index, String to, int amount,
      {int? baseOperationCustomFee}) async {
    log.info('TezosService.sendTransaction: $to, $amount');
    return _retryOnError<String?>((client) async {
      final operation = await client.transferOperation(
        publicKey: await wallet.getTezosPublicKey(index: index),
        destination: to,
        amount: amount,
      );
      await operation.execute(
          (forgedHex) => wallet.tezosSignTransaction(forgedHex, index: index),
          baseOperationCustomFee: baseOperationCustomFee);
      return operation.result.id;
    });
  }

  @override
  Future<String> signMessage(
      WalletStorage wallet, int index, Uint8List message) async {
    final signature = await wallet.tezosSignMessage(message, index: index);

    return crypto.encodeWithPrefix(prefix: Prefixes.edsig, bytes: signature);
  }

  @override
  Future<Operation> getFa2TransferOperation(String contract, String from,
      String to, String tokenId, int quantity) async {
    final params = [
      {
        'prim': 'Pair',
        'args': [
          {'string': from},
          [
            {
              'args': [
                {'string': to},
                {
                  'prim': 'Pair',
                  'args': [
                    {'int': tokenId},
                    {'int': '$quantity'}
                  ]
                }
              ],
              'prim': 'Pair'
            }
          ]
        ]
      }
    ];

    return TransactionOperation(
        amount: 0,
        destination: contract,
        entrypoint: 'transfer',
        params: params);
  }

  Future<T> _retryOnError<T>(Future<T> Function(TezartClient) func,
          {bool doRetry = true}) =>
      _networkIssueManager.retryOnConnectIssueTx(() => _retryOnNodeError(func),
          maxRetries: doRetry ? 3 : 0);

  Future<T> _retryOnNodeError<T>(Future<T> Function(TezartClient) func) async {
    try {
      return await func(_tezartClient);
    } on TezartNodeError catch (_) {
      if (Environment.appTestnetConfig) {
        rethrow;
      }
      _changeNode();
      return await func(_tezartClient);
    }
  }
}
