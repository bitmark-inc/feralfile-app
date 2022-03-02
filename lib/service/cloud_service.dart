import 'package:autonomy_flutter/util/cloud_channel.dart';
import 'package:flutter/material.dart';

class CloudService implements CloudHandler {
  late CloudChannel _cloudChannel;
  ValueNotifier<bool> isAvailableNotifier = ValueNotifier(false);

  CloudService() {
    _cloudChannel = CloudChannel(handler: this);
  }

  @override
  void observeCloudStatus(bool isAvailable) {
    isAvailableNotifier.value = isAvailable;
  }
}
