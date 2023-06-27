//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

abstract class KeySyncEvent {}

class ToggleKeySyncEvent extends KeySyncEvent {
  ToggleKeySyncEvent();
}

class ChangeKeyChainEvent extends KeySyncEvent {
  final bool isLocal;

  ChangeKeyChainEvent(this.isLocal);
}

class ProceedKeySyncEvent extends KeySyncEvent {}

class KeySyncState {
  final bool isLocalSelected;
  final bool? isProcessing;
  bool isLocalSelectedTmp;

  KeySyncState(
      this.isLocalSelected, this.isProcessing, this.isLocalSelectedTmp);

  KeySyncState copyWith(
      {bool? isLocalSelected, bool? isProcessing, bool? isLocalSelectedTmp}) {
    return KeySyncState(
        isLocalSelected ?? this.isLocalSelected,
        isProcessing ?? this.isProcessing,
        isLocalSelectedTmp ?? this.isLocalSelectedTmp);
  }
}
