//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';

class HiddenArtworksBloc extends AuBloc<HiddenArtworksEvent, List<AssetToken>> {
  AppDatabase _appDatabase;

  HiddenArtworksBloc(this._appDatabase) : super([]) {
    on<HiddenArtworksEvent>((event, emit) async {
      final assets = await _appDatabase.assetDao.findAllHiddenAssets();
      emit(assets);
    });
  }
}

class HiddenArtworksEvent {}
