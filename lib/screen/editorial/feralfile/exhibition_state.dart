//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/ff_account.dart';

abstract class ExhibitionEvent {}

class GetExhibitionEvent extends ExhibitionEvent {
  final String id;

  GetExhibitionEvent(this.id);
}

class ExhibitionState {
  final Exhibition? exhibition;

  ExhibitionState(this.exhibition);
}
