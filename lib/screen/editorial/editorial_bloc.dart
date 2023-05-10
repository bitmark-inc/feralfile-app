//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/pubdoc_api.dart';
import 'package:autonomy_flutter/screen/editorial/editorial_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/editorial_service.dart';

class EditorialBloc extends AuBloc<EditorialEvent, EditorialState> {
  final PubdocAPI _pubdocAPI;
  final _configurationService = injector<ConfigurationService>();
  final _editorialService = injector<EditorialService>();

  EditorialBloc(this._pubdocAPI) : super(EditorialState(editorial: [])) {
    on<GetEditorialEvent>((event, emit) async {
      final editorial = await _pubdocAPI.getEditorialInfo();
      emit(
        EditorialState(editorial: editorial.editorial),
      );
      await _configurationService.setLastTimeOpenEditorial(DateTime.now());
    });

    on<OpenEditorialEvent>((event, emit) async {
      await _configurationService.setLastTimeOpenEditorial(DateTime.now());
      _editorialService.unviewedCount.value = 0;
    });
  }
}
