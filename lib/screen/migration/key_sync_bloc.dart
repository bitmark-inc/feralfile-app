import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/screen/migration/key_sync_state.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class KeySyncBloc extends Bloc<KeySyncEvent, KeySyncState> {
  BackupService _backupService;
  CloudDatabase _cloudDatabase;

  KeySyncBloc(this._backupService, this._cloudDatabase)
      : super(KeySyncState(true, null)) {
    on<ToggleKeySyncEvent>((event, emit) async {
      emit(KeySyncState(event.isLocal, state.isProcessing));
    });

    on<ProceedKeySyncEvent>((event, emit) async {
      emit(KeySyncState(state.isLocalSelected, true));

      final accounts = await _cloudDatabase.personaDao.getDefaultPersonas();
      if (accounts.length < 2) return;

      final cloudWallet = accounts[1].wallet();

      final cloudBackupVersion = await _backupService.fetchBackupVersion(cloudWallet);

      if (cloudBackupVersion.isNotEmpty) {
        final tmpCloudDbName = 'tmp_cloud_database.db';
        await _backupService.restoreCloudDatabase(cloudWallet, cloudBackupVersion, dbName: tmpCloudDbName);

        final tmpCloudDb = await $FloorCloudDatabase
            .databaseBuilder(tmpCloudDbName)
            .addMigrations([
          migrateCloudV1ToV2,
          migrateCloudV2ToV3,
        ]).build();

        final connections = await tmpCloudDb.connectionDao.getConnections();
        await _cloudDatabase.connectionDao.insertConnections(connections);
      }

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

      emit(KeySyncState(state.isLocalSelected, false));
    });
  }
}

