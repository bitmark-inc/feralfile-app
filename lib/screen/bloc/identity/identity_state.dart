part of 'identity_bloc.dart';

abstract class IdentityEvent {}

class GetIdentityEvent extends IdentityEvent {
  final Iterable<String> addresses;

  GetIdentityEvent(this.addresses);
}

class IdentityState {
  Map<String, String> identityMap;

  IdentityState(this.identityMap);
}
