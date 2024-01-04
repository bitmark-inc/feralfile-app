//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/screen/migration/key_sync_state.dart';
import 'package:autonomy_flutter/service/auth_firebase_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';

class KeySyncBloc extends AuBloc<KeySyncEvent, KeySyncState> {
  final BackupService _backupService;
  final CloudDatabase _cloudDatabase;
  final AuthFirebaseService _authFirebaseService;

  KeySyncBloc(
      this._backupService, this._cloudDatabase, this._authFirebaseService)
      : super(KeySyncState(true, null, true)) {
    on<ToggleKeySyncEvent>((event, emit) async {
      emit(state.copyWith(isLocalSelected: state.isLocalSelectedTmp));
    });

    on<ChangeKeyChainEvent>((event, emit) {
      emit(state.copyWith(isLocalSelectedTmp: event.isLocal));
    });

    on<ProceedKeySyncEvent>((event, emit) async {
      emit(state.copyWith(
          isProcessing: true, isLocalSelectedTmp: state.isLocalSelected));

      final defaultPersonaes =
          await _cloudDatabase.personaDao.getDefaultPersonas();
      if (defaultPersonaes.length < 2) {
        return;
      }
      final localDefaultPersona = defaultPersonaes[0];
      final cloudDefaultPersona = defaultPersonaes[1];

      final cloudWallet = cloudDefaultPersona.wallet();
      final localWallet = localDefaultPersona.wallet();

      if (state.isLocalSelected) {
        await _backupService.deleteAllProfiles(cloudWallet);
        cloudDefaultPersona.defaultAccount = null;
        await _cloudDatabase.personaDao.updatePersona(cloudDefaultPersona);
      } else {
        await _backupService.deleteAllProfiles(localWallet);
        localDefaultPersona.defaultAccount = null;
        await _cloudDatabase.personaDao.updatePersona(localDefaultPersona);
      }

      emit(state.copyWith(isProcessing: false));
    });
  }
}
