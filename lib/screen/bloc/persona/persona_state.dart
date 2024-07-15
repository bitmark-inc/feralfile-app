//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

part of 'persona_bloc.dart';

abstract class PersonaEvent {}

class CreatePersonaAddressesEvent extends PersonaEvent {
  final String? name;
  final WalletType walletType;

  CreatePersonaAddressesEvent(this.walletType, {this.name});
}

class GetListPersonaEvent extends PersonaEvent {
  final bool useDidKeyForAlias;

  GetListPersonaEvent({
    this.useDidKeyForAlias = false,
  });
}

class ImportPersonaEvent extends PersonaEvent {
  final String words;

  ImportPersonaEvent(this.words);
}

class GetInfoPersonaEvent extends PersonaEvent {
  final String uuid;

  GetInfoPersonaEvent(this.uuid);
}

class DeletePersonaEvent extends PersonaEvent {
  final Persona persona;

  // constructor
  DeletePersonaEvent(this.persona);
}

class PersonaState {
  ActionState createAccountState = ActionState.notRequested;
  ActionState namePersonaState = ActionState.notRequested;
  ActionState deletePersonaState = ActionState.notRequested;

  Persona? persona;
  List<Persona>? personas;

  PersonaState({
    this.createAccountState = ActionState.notRequested,
    this.namePersonaState = ActionState.notRequested,
    this.deletePersonaState = ActionState.notRequested,
    this.persona,
    this.personas,
  });

  PersonaState copyWith({
    ActionState? createAccountState,
    ActionState? namePersonaState,
    ActionState? deletePersonaState,
    Persona? persona,
    List<Persona>? personas,
  }) => PersonaState(
      createAccountState: createAccountState ?? this.createAccountState,
      namePersonaState: namePersonaState ?? this.namePersonaState,
      deletePersonaState: deletePersonaState ?? this.deletePersonaState,
      persona: persona ?? this.persona,
      personas: personas ?? this.personas,
    );
}
