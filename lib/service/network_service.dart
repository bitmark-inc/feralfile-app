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

class NetworkService {
  static const String _defaultListenerId = 'defaultListenerId';
  final Connectivity _connectivity = Connectivity();
  List<ConnectivityResult> _connectivityResult = [ConnectivityResult.none];
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
        isWifiNotifier.value = isWifi;
      });
    }, id: _defaultListenerId);
  }

  void addListener(void Function(List<ConnectivityResult> result) fn,
      {String? id}) {
    _connectivity.onConnectivityChanged.listen(fn);
  }

  bool get isWifi => _connectivityResult.contains(ConnectivityResult.wifi);
}
