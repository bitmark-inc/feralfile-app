//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';

part 'persona_state.dart';

class PersonaBloc extends AuBloc<PersonaEvent, PersonaState> {
  CloudDatabase _cloudDB;
  AccountService _accountService;
  AuditService _auditService;
  ConfigurationService _configurationService;

  PersonaBloc(this._cloudDB, this._accountService, this._configurationService,
      this._auditService)
      : super(PersonaState()) {
    on<CreatePersonaEvent>((event, emit) async {
      emit(PersonaState(createAccountState: ActionState.loading));
      // await Future.delayed(SHOW_DIALOG_DURATION);

      if (!_configurationService.isDoneOnboarding()) {
        final account = await _accountService.getDefaultAccount();
        final persona = await _cloudDB.personaDao.findById(account.uuid);
        emit(PersonaState(
            createAccountState: ActionState.done, persona: persona));
      } else {
        final persona = await _accountService.createPersona();
        emit(PersonaState(
            createAccountState: ActionState.done, persona: persona));
      }

      await Future.delayed(Duration(microseconds: 500), () {
        emit(state.copyWith(createAccountState: ActionState.notRequested));
      });
    });

    on<GetListPersonaEvent>((event, emit) async {
      final personas = await _cloudDB.personaDao.getPersonas();
      List<Persona> _namedPersonas = [];

      for (var persona in personas) {
        if (persona.name.isEmpty) {
          final address = await persona.wallet().getETHEip55Address();
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
      await _auditService.auditPersonaAction('name', updatedPersona);

      emit(state.copyWith(
          namePersonaState: ActionState.done, persona: updatedPersona));
    });
  }
}
