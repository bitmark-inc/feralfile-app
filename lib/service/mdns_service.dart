//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/service/network_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';

class MDnsService {
  static const String _serviceType = '_feralFileCanvas._tcp';
  static const int _scanningTime = 3;
  final NetworkService _networkService;

  MDnsService(this._networkService);

  Future<List<CanvasDevice>> findCanvas() async {
    final devices = <CanvasDevice>[];
    if (!_networkService.isWifi) {
      return devices;
    }
    BonsoirDiscovery discovery = BonsoirDiscovery(type: _serviceType);
    log.info('[MDnsService] Looking for devices');
    await discovery.ready;
    discovery.eventStream!.listen((event) {
      log.info(event.type);
      switch (event.type) {
        case BonsoirDiscoveryEventType.discoveryServiceFound:
          log.info('[MDnsService] Service found : ${event.service}');
          event.service!.resolve(discovery.serviceResolver);
        case BonsoirDiscoveryEventType.discoveryServiceResolved:
          final attribute = event.service!.attributes;
          log.info('[MDnsService] Service resolved : ${event.service}');
          final name = event.service!.name;
          final ip = attribute['ip'];
          final port = int.tryParse(attribute['port'] ?? '');
          final id = attribute['id'];
          if (ip != null && port != null && id != null) {
            if (devices
                .any((element) => element.id == id && element.ip == ip)) {
              return;
            }
            devices.add(CanvasDevice(
              id: id,
              ip: ip,
              port: port,
              name: name,
            ));
          }
        case BonsoirDiscoveryEventType.discoveryServiceResolveFailed:
          log.info('[MDnsService] Service resolved failed : ${event.service}');
        default:
      }
    });
    await discovery.start();
    await Future.delayed(const Duration(seconds: _scanningTime), () {
      discovery.stop();
    });
    return devices;
  }
}
