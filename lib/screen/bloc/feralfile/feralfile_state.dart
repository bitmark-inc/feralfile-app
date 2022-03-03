part of 'feralfile_bloc.dart';

abstract class FeralFileEvent {}

class LinkFFAccountInfoEvent extends FeralFileEvent {
  final String token;

  LinkFFAccountInfoEvent(this.token);
}

class LinkFFWeb3AccountEvent extends FeralFileEvent {
  final String topic;
  final String source;
  final WalletStorage wallet;

  LinkFFWeb3AccountEvent(this.topic, this.source, this.wallet);
}

class GetFFAccountInfoEvent extends FeralFileEvent {
  final Connection connection;

  GetFFAccountInfoEvent(this.connection);
}

class FeralFileState {
  ActionState refreshState;
  Connection? connection;
  FeralFileBlocStateEvent? event;

  FeralFileState(
      {this.refreshState = ActionState.notRequested,
      this.connection,
      this.event});

  FeralFileState copyWith({
    ActionState? refreshState,
    Connection? connection,
    FeralFileBlocStateEvent? event,
  }) {
    return FeralFileState(
      refreshState: refreshState ?? this.refreshState,
      connection: connection ?? this.connection,
      event: event ?? this.event,
    );
  }

  FeralFileState setEvent(FeralFileBlocStateEvent? event) {
    return FeralFileState(
      refreshState: this.refreshState,
      connection: this.connection,
      event: event,
    );
  }

  bool get isError {
    if (event == null) return false;
    if (event is LinkAccountSuccess) return false;
    return true;
  }
}

abstract class FeralFileBlocStateEvent {}

class LinkAccountSuccess extends FeralFileBlocStateEvent {
  final Connection connection;

  LinkAccountSuccess(this.connection);
}

class AlreadyLinkedError extends FeralFileBlocStateEvent {
  final Connection connection;

  AlreadyLinkedError(this.connection);
}

class FFNotConnected extends FeralFileBlocStateEvent {}

class NotFFLoggedIn extends FeralFileBlocStateEvent {}
