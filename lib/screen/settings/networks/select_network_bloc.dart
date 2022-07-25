//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';

class SelectNetworkBloc extends AuBloc<SelectNetworkEvent, Network> {
  ConfigurationService _configurationService;

  SelectNetworkBloc(this._configurationService)
      : super(_configurationService.getNetwork()) {
    on<SelectNetworkEvent>((event, emit) async {
      await _configurationService.setNetwork(event.network);
      emit(event.network);
    });
  }
}

class SelectNetworkEvent {
  final Network network;

  SelectNetworkEvent(this.network);
}
