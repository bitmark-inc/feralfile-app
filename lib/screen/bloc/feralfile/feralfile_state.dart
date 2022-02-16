part of 'feralfile_bloc.dart';

abstract class FeralFileEvent {}

class LinkFFAccountInfoEvent extends FeralFileEvent {
  final String token;

  LinkFFAccountInfoEvent(this.token);
}

class GetFFAccountInfoEvent extends FeralFileEvent {
  final Connection connection;

  GetFFAccountInfoEvent(this.connection);
}

class FeralFileState {
  ActionState linkState;
  ActionState refreshState;
  Connection? connection;

  FeralFileState(
      {this.refreshState = ActionState.notRequested,
      this.linkState = ActionState.notRequested,
      this.connection});

  FeralFileState copyWith({
    ActionState? refreshState,
    ActionState? linkState,
    Connection? connection,
  }) {
    return FeralFileState(
      refreshState: refreshState ?? this.refreshState,
      linkState: linkState ?? this.linkState,
      connection: connection ?? this.connection,
    );
  }
}
