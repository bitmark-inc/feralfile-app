part of 'persona_bloc.dart';

abstract class PersonaEvent {}

class CreatePersonaEvent extends PersonaEvent {}

class GetInfoPersonaEvent extends PersonaEvent {
  final String uuid;

  GetInfoPersonaEvent(this.uuid);
}

class NamePersonaEvent extends PersonaEvent {
  final String name;

  NamePersonaEvent(this.name);
}

class PersonaState {
  ActionState createAccountState = ActionState.notRequested;
  ActionState namePersonaState = ActionState.notRequested;

  Persona? persona;

  PersonaState(
      {this.createAccountState = ActionState.notRequested,
      this.namePersonaState = ActionState.notRequested,
      this.persona});

  PersonaState copyWith({
    ActionState? createAccountState,
    ActionState? namePersonaState,
    Persona? persona,
  }) {
    return PersonaState(
      createAccountState: createAccountState ?? this.createAccountState,
      namePersonaState: namePersonaState ?? this.namePersonaState,
      persona: persona ?? this.persona,
    );
  }
}
