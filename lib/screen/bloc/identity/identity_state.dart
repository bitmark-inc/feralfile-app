part of 'identity_bloc.dart';

abstract class IdentityEvent {}

/// Fetch for identities and emit events after getting from database and API
class GetIdentityEvent extends IdentityEvent {
  final Iterable<String> addresses;

  GetIdentityEvent(this.addresses);
}

/// Fetch for identities and do not emit events
class FetchIdentityEvent extends IdentityEvent {
  final Iterable<String> addresses;

  FetchIdentityEvent(this.addresses);
}

class IdentityState {
  Map<String, String> identityMap;

  IdentityState(this.identityMap);
}
