//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/util/log.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class NetworkService {
  static const String _defaultListenerId = 'defaultListenerId';
  final Connectivity _connectivity = Connectivity();
  final Map<String, StreamSubscription<ConnectivityResult>> _listener = {};
  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  final ValueNotifier<bool> isWifiNotifier = ValueNotifier(false);
  Timer? _timer;

  static const String canvasBlocListenerId = 'canvasBlocListenerId';
  static const String beaconListenerId = 'beaconListenerId';

  NetworkService() {
    addListener((result) {
      log.info('[NetworkService] Network changed: $result');
      _connectivityResult = result;

      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 1), () {
        isWifiNotifier.value = result == ConnectivityResult.wifi;
      });
    }, id: _defaultListenerId);
  }

  String addListener(Function(ConnectivityResult result) fn, {String? id}) {
    final listenerId = id ?? const Uuid().v4();
    log.info('[NetworkService] add listener $listenerId');
    final connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(fn);
    _listener[listenerId] = connectivitySubscription;
    return listenerId;
  }

  Future<void> removeListener(String id) async {
    final connectivitySubscription = _listener[id];
    if (connectivitySubscription != null) {
      log.info('[NetworkService] remove listener $id');
      await connectivitySubscription.cancel();
      _listener.remove(id);
    }
  }

  bool get isWifi => _connectivityResult == ConnectivityResult.wifi;
}
