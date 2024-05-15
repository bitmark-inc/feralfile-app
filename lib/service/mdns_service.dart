import 'package:autonomy_flutter/util/log.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';

class MDnsService {
  static const String _serviceType = '_feralFileCanvas._tcp';
  static const int _scanningTime = 2;

  Future<List<CanvasDevice>> findCanvas() async {
    BonsoirDiscovery discovery = BonsoirDiscovery(type: _serviceType);
    final devices = <CanvasDevice>[];
    log.info('[MDnsService] Looking for devices');
    await discovery.ready;
    discovery.eventStream!.listen((event) {
      log.info(event.type);
      if (event.service != null &&
          (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved ||
              event.type == BonsoirDiscoveryEventType.discoveryServiceFound)) {
        final attribute = event.service!.attributes;
        log.info('[MDnsService] Service found : $attribute');
        final name = event.service!.name;
        final ip = attribute['ip'];
        final port = int.tryParse(attribute['port'] ?? '');
        final id = attribute['id'];
        if (ip != null && port != null && id != null) {
          if (devices.any((element) => element.id == id && element.ip == ip)) {
            return;
          }
          devices.add(CanvasDevice(
            id: id,
            ip: ip,
            port: port,
            name: name,
          ));
        }
      }
    });
    await discovery.start();
    await Future.delayed(const Duration(seconds: _scanningTime), () {
      discovery.stop();
    });

    print('3--------------${DateTime.now().millisecondsSinceEpoch}');
    return devices;
  }
}
