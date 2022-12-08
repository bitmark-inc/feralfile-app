//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/gateway/pubdoc_api.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/screen/editorial/editorial_state.dart';
import 'package:autonomy_flutter/screen/editorial/feralfile/exhibition_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:collection/collection.dart';

class ExhibitionBloc extends AuBloc<ExhibitionEvent, ExhibitionState> {
  final FeralFileService _feralFileService;

  ExhibitionBloc(this._feralFileService)
      : super(ExhibitionState(null)) {
    on<GetExhibitionEvent>((event, emit) async {
      final exhibition = await _feralFileService.getExhibition(event.id);
      emit(
        ExhibitionState(exhibition),
      );
    });
  }
}
