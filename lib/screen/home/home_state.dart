//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';

abstract class HomeEvent {}

class HomeConnectWCEvent extends HomeEvent {
  final String uri;

  HomeConnectWCEvent(this.uri);
}

class HomeConnectTZEvent extends HomeEvent {
  final String uri;

  HomeConnectTZEvent(this.uri);
}

class RefreshTokensEvent extends HomeEvent {}

class SubRefreshTokensEvent extends HomeEvent {}

class ReindexIndexerEvent extends HomeEvent {}

class HomeState {
  List<AssetToken>? tokens;
  ActionState fetchTokenState;

  HomeState({
    this.tokens = null,
    this.fetchTokenState = ActionState.notRequested,
  });

  HomeState copyWith({
    List<AssetToken>? tokens,
    ActionState? fetchTokenState,
  }) {
    return HomeState(
      tokens: tokens ?? this.tokens,
      fetchTokenState: fetchTokenState ?? this.fetchTokenState,
    );
  }
}
