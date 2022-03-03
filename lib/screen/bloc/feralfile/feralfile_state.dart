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
  ActionState linkState;
  ActionState refreshState;
  Connection? connection;
  String errorMessage = '';

  FeralFileState(
      {this.refreshState = ActionState.notRequested,
      this.linkState = ActionState.notRequested,
      this.connection,
      this.errorMessage = ''});

  FeralFileState copyWith({
    ActionState? refreshState,
    ActionState? linkState,
    Connection? connection,
    String? errorMessage,
  }) {
    return FeralFileState(
      refreshState: refreshState ?? this.refreshState,
      linkState: linkState ?? this.linkState,
      connection: connection ?? this.connection,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
