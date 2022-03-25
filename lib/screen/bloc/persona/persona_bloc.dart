import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/model/p2p_peer.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:bloc/bloc.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet_connect/wallet_connect.dart';

part 'persona_state.dart';

class PersonaBloc extends Bloc<PersonaEvent, PersonaState> {
  CloudDatabase _cloudDB;
  AccountService _accountService;

  PersonaBloc(
      this._cloudDB, this._accountService)
      : super(PersonaState()) {
    on<CreatePersonaEvent>((event, emit) async {
      emit(PersonaState(createAccountState: ActionState.loading));
      // await Future.delayed(SHOW_DIALOG_DURATION);

      final persona = await _accountService.createPersona();

      emit(
          PersonaState(createAccountState: ActionState.done, persona: persona));

      await Future.delayed(Duration(microseconds: 500), () {
        emit(state.copyWith(createAccountState: ActionState.notRequested));
      });
    });

    on<GetListPersonaEvent>((event, emit) async {
      final personas = await _cloudDB.personaDao.getPersonas();
      List<Persona> _namedPersonas = [];

      for (var persona in personas) {
        if (persona.name.isEmpty) {
          final address = await persona.wallet().getETHAddress();
          _namedPersonas.add(persona.copyWith(name: address.mask(4)));
        } else {
          _namedPersonas.add(persona);
        }
      }

      _namedPersonas.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      emit(state.copyWith(personas: _namedPersonas));
    });

    on<GetInfoPersonaEvent>((event, emit) async {
      final persona = await _cloudDB.personaDao.findById(event.uuid);
      emit(state.copyWith(persona: persona));
    });

    on<NamePersonaEvent>((event, emit) async {
      final oldPersona = state.persona;
      if (oldPersona == null) return;
      emit(state.copyWith(namePersonaState: ActionState.loading));

      await oldPersona.wallet().updateName(event.name);
      final updatedPersona = oldPersona.copyWith(name: event.name);
      await _cloudDB.personaDao.updatePersona(updatedPersona);

      emit(state.copyWith(
          namePersonaState: ActionState.done, persona: updatedPersona));
    });
  }
}
