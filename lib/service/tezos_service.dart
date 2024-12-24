//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: implementation_imports

import 'dart:math';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/network_issue_manager.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:tezart/tezart.dart';

const baseOperationCustomFeeLow = 100;
const baseOperationCustomFeeMedium = 150;
const baseOperationCustomFeeHigh = 200;

abstract class TezosService {
  Future<int> getBalance(String address, {bool doRetry = false});
}

class TezosServiceImpl extends TezosService {
  TezosServiceImpl(this._networkIssueManager);

  TezartClient get _tezartClient => _getClient();
  final NetworkIssueManager _networkIssueManager;

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
    final publicTezosNodes =
        injector<RemoteConfigService>().getConfig<List<dynamic>>(
      ConfigGroup.dAppUrls,
      ConfigKey.tezosNodes,
      <String>[],
    ).cast<String>()
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
      doRetry: doRetry,
    );
  }

  Future<T> _retryOnError<T>(
    Future<T> Function(TezartClient) func, {
    bool doRetry = true,
  }) =>
      _networkIssueManager.retryOnConnectIssueTx(
        () => _retryOnNodeError(func),
        maxRetries: doRetry ? 3 : 0,
      );

  Future<T> _retryOnNodeError<T>(Future<T> Function(TezartClient) func) async {
    try {
      return await func(_tezartClient);
    } on TezartNodeError catch (_) {
      if (Environment.appTestnetConfig) {
        rethrow;
      }
      _changeNode();
      return func(_tezartClient);
    }
  }
}
