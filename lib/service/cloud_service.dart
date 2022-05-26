//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

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
