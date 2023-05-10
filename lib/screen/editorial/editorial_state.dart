//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/editorial.dart';
import 'package:autonomy_flutter/model/ff_account.dart';

abstract class EditorialEvent {}

class GetEditorialEvent extends EditorialEvent {
  GetEditorialEvent();
}

class OpenEditorialEvent extends EditorialEvent {
  OpenEditorialEvent();
}

class EditorialState {
  final List<EditorialPost> editorial;
  final Exhibition? exhibition;

  EditorialState({required this.editorial, this.exhibition});
}
