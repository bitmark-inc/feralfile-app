//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/screen/migration/key_sync_state.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:sentry/sentry.dart';

class KeySyncBloc extends AuBloc<KeySyncEvent, KeySyncState> {
  final BackupService _backupService;
  final CloudDatabase _cloudDatabase;

  KeySyncBloc(this._backupService, this._cloudDatabase)
      : super(KeySyncState(true, null, true)) {
    on<ToggleKeySyncEvent>((event, emit) async {
      emit(state.copyWith(isLocalSelected: state.isLocalSelectedTmp));
    });

    on<ChangeKeyChainEvent>((event, emit) {
      emit(state.copyWith(isLocalSelectedTmp: event.isLocal));
    });

    on<ProceedKeySyncEvent>((event, emit) async {
      emit(state.copyWith(
          isProcessing: true,
          isLocalSelectedTmp: state.isLocalSelected,
          isError: false));

      final accounts = await _cloudDatabase.personaDao.getDefaultPersonas();
      if (accounts.length < 2) {
        return;
      }

      final cloudWallet = accounts[1].wallet();
      try {
        final cloudBackupVersion =
            await _backupService.fetchBackupVersion(cloudWallet);

        if (cloudBackupVersion.isNotEmpty) {
          const tmpCloudDbName = 'tmp_cloud_database.db';
          await _backupService.restoreCloudDatabase(
              cloudWallet, cloudBackupVersion,
              dbName: tmpCloudDbName);

          final tmpCloudDb = await $FloorCloudDatabase
              .databaseBuilder(tmpCloudDbName)
              .addMigrations(cloudDatabaseMigrations)
              .build();

          final connections = await tmpCloudDb.connectionDao.getConnections();
          await _cloudDatabase.connectionDao.insertConnections(connections);
        }
        log.info('ProceedKeySyncEvent done restore connection');

        if (state.isLocalSelected) {
          final cloudDefaultPersona = accounts[1];
          await _backupService.deleteAllProfiles(cloudWallet);
          cloudDefaultPersona.defaultAccount = null;
          await _cloudDatabase.personaDao.updatePersona(cloudDefaultPersona);
        } else {
          final localDefaultPersona = accounts[0];
          await _backupService.deleteAllProfiles(localDefaultPersona.wallet());
          localDefaultPersona.defaultAccount = null;
          await _cloudDatabase.personaDao.updatePersona(localDefaultPersona);
        }
      } catch (e) {
        log.info('ProceedKeySyncEvent select local'
            ' ${state.isLocalSelected} error: $e');
        unawaited(Sentry.captureException('ProceedKeySyncEvent select local'
            ' ${state.isLocalSelected} error: $e'));
        emit(state.copyWith(isError: true, isProcessing: false));
      }

      emit(state.copyWith(isProcessing: false));
    });
  }
}
