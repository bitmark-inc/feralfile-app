//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

abstract class ForgetExistEvent {}

class UpdateCheckEvent extends ForgetExistEvent {
  final bool isChecked;

  UpdateCheckEvent(this.isChecked);
}

class ConfirmForgetExistEvent extends ForgetExistEvent {}

class ConfirmEraseDeviceInfoEvent extends ForgetExistEvent {}

class ForgetExistState {
  final bool isChecked;
  final bool? isProcessing;

  ForgetExistState(this.isChecked, this.isProcessing);
}
