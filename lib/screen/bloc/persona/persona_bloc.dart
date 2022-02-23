import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:uuid/uuid.dart';

part 'persona_state.dart';

class PersonaBloc extends Bloc<PersonaEvent, PersonaState> {
  CloudDatabase _cloudDB;

  PersonaBloc(this._cloudDB) : super(PersonaState()) {
    on<CreatePersonaEvent>((event, emit) async {
      emit(PersonaState(createAccountState: ActionState.loading));
      await Future.delayed(SHOW_DIALOG_DURATION);

      final uuid = Uuid().v4();
      final walletStorage = LibAukDart.getWallet(uuid);
      await walletStorage.createKey("");

      final persona = Persona.newPersona(uuid: uuid, name: "");
      await _cloudDB.personaDao.insertPersona(persona);

      emit(
          PersonaState(createAccountState: ActionState.done, persona: persona));
    });

    on<GetInfoPersonaEvent>((event, emit) async {
      final persona = await _cloudDB.personaDao.findById(event.uuid);
      emit(state.copyWith(persona: persona));
    });

    on<NamePersonaEvent>((event, emit) async {
      final oldPersona = state.persona;
      if (oldPersona == null) return;
      emit(state.copyWith(namePersonaState: ActionState.loading));

      final updatedPersona = oldPersona.copyWith(name: event.name);
      await _cloudDB.personaDao.updatePersona(updatedPersona);

      emit(state.copyWith(
          namePersonaState: ActionState.done, persona: updatedPersona));
    });

    on<ImportPersonaEvent>((event, emit) async {
      log.info('[PersonaBloc] ImportPersonaEvent');
      try {
        emit(state.copyWith(importPersonaState: ActionState.loading));
        await Future.delayed(SHOW_DIALOG_DURATION);

        final uuid = Uuid().v4();
        final walletStorage = LibAukDart.getWallet(uuid);
        await walletStorage.importKey(
            event.words, "", DateTime.now().microsecondsSinceEpoch);

        final persona = Persona.newPersona(uuid: uuid, name: "");
        await _cloudDB.personaDao.insertPersona(persona);

        emit(state.copyWith(
            importPersonaState: ActionState.done, persona: persona));
      } catch (exception) {
        emit(state.copyWith(importPersonaState: ActionState.error));
      }
    });

    on<DeletePersonaEvent>((event, emit) async {
      log.info('[PersonaBloc] DeletePersonaEvent');
      emit(state.copyWith(deletePersonaState: ActionState.loading));

      final deletedPersona = event.persona;
      _cloudDB.personaDao.deletePersona(deletedPersona);
      LibAukDart.getWallet(deletedPersona.uuid).removeKeys();

      final connections = await _cloudDB.connectionDao.getConnections();
      for (var connection in connections) {
        switch (connection.connectionType) {
          case 'dappConnect':
            if (deletedPersona.uuid == connection.wcConnection?.personaUuid) {
              _cloudDB.connectionDao.deleteConnection(connection);
            }
            break;

          case 'beaconP2PPeer':
            if (deletedPersona.uuid ==
                connection.beaconConnectConnection?.personaUuid) {
              _cloudDB.connectionDao.deleteConnection(connection);
            }
            break;

          // Note: Should app delete feralFileWeb3 too ??
        }
      }

      emit(state.copyWith(deletePersonaState: ActionState.done));
    });
  }
}
