//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/pubdoc_api.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:flutter/foundation.dart';

abstract class EditorialService {
  ValueNotifier<int> get unviewedCount;

  Future checkNewEditorial();
}

class EditorialServiceImpl extends EditorialService {
  @override
  ValueNotifier<int> unviewedCount = ValueNotifier(0);

  final ConfigurationService _configurationService;

  EditorialServiceImpl(this._configurationService);

  @override
  Future checkNewEditorial() async {
    final lastTimeOpenEditorial =
        _configurationService.getLastTimeOpenEditorial();
    final editorial = await injector<PubdocAPI>().getEditorialInfo();
    final unreadEditorial = editorial.editorial.where((element) {
      return element.publishedAt
              ?.isAfter(lastTimeOpenEditorial ?? DateTime(1970)) ??
          false;
    }).length;
    unviewedCount.value = unreadEditorial;
  }
}
