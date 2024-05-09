import 'package:autonomy_flutter/util/log.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:multicast_dns/multicast_dns.dart';

class MDnsService {
  static const String _serviceType = '_feralFileCanvas._tcp';
  final MDnsClient _client;
  bool _isStarted = false;

  MDnsService() : _client = MDnsClient();

  Future<List<CanvasDevice>> findCanvas() async {
    final devices = <CanvasDevice>[];
    log.info('[MDnsService] Looking for devices');
    if (!_isStarted) {
      await start();
    }
    await _client
        .lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer(_serviceType),
    )
        .forEach((PtrResourceRecord record) async {
      await for (final TxtResourceRecord txt
          in _client.lookup<TxtResourceRecord>(
        ResourceRecordQuery.text(record.domainName),
      )) {
        log.info('[MDnsService] Found device: ${txt.text}');
        final name = record.domainName.split('.').first;
        final text = txt.text;
        final attributes = text.split('\n')
          ..removeWhere((element) => !element.contains('='));
        final Map<String, String> map = {};
        for (final attribute in attributes) {
          final parts = attribute.split('=');
          map[parts.first] = parts.last;
        }
        final ip = map['ip'];
        final port = map['port'];
        final id = map['id'];
        if (ip != null && port != null && id != null) {
          if (devices.any((element) => element.id == id && element.ip == ip)) {
            continue;
          }
          devices.add(CanvasDevice(
            id: id,
            ip: ip,
            port: int.parse(port),
            name: name,
          ));
        }
      }
    });
    return devices;
  }

  Future<void> start() async {
    if (_isStarted) {
      return;
    }
    await _client.start();
    _isStarted = true;
  }

  Future<void> stop() async {
    _client.stop();
  }
}
