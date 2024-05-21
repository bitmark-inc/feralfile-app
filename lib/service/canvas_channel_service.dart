//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/service/network_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';

class CanvasChannelService {
  final NetworkService _networkService;

  CanvasChannelService(this._networkService) {
    _networkService.addListener((result) async {
      log.info('[CanvasChannelService] shut down all channel');
      await Future.wait(_channels.values.map((e) async {
        await e.shutdown();
      }));
      _channels.clear();
    });
  }

  final Map<String, ClientChannel> _channels = {};

  CanvasControlV2Client getStubV2(CanvasDevice device) {
    final channel = _getChannel(device);
    return CanvasControlV2Client(channel);
  }

  CanvasControlClient getStubV1(CanvasDevice device) {
    final channel = _getChannel(device);
    return CanvasControlClient(channel);
  }

  ClientChannel _getChannel(CanvasDevice device) =>
      _channels[device.ip] ?? _createNewChannel(device);

  ClientChannel _createNewChannel(CanvasDevice device) {
    final newChannel = ClientChannel(
      device.ip,
      port: device.port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
        keepAlive: ClientKeepAliveOptions(pingInterval: Duration(seconds: 2)),
      ),
    );
    _channels[device.ip] = newChannel;
    return newChannel;
  }
}
