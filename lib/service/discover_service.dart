import 'package:autonomy_flutter/service/discover_handler.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:bonsoir/bonsoir.dart';

class DiscoverService {
  final BonsoirDiscovery _discover;
  static const String _type = '_feral-file-cast._tcp';
  final DiscoverHandler _handler;

  DiscoverService(this._handler) : _discover = BonsoirDiscovery(type: _type);

  Future<void> discover() async {
    await _discover.ready;
    _discover.eventStream!.listen((event) {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
        log.info(
            '[DiscoverService] Service resolved : ${event.service?.toJson()}');
        if (event.service != null) {
          _handler.handleServiceResolved(event.service!);
        }
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
        log.info('[DiscoverService] Service lost : ${event.service?.toJson()}');
        if (event.service != null) {
          _handler.handleServiceLost(event.service!);
        }
      }
    });
    await _discover.start();
  }

  Future<void> stop() async {
    await _discover.stop();
  }
}
