part of 'tezos_bloc.dart';

abstract class TezosEvent {}

class GetTezosBalanceWithAddressEvent extends TezosEvent {
  final String address;

  GetTezosBalanceWithAddressEvent(this.address);
}

class GetTezosBalanceWithUUIDEvent extends TezosEvent {
  final String uuid;

  GetTezosBalanceWithUUIDEvent(this.uuid);
}

class GetTezosAddressEvent extends TezosEvent {
  final String uuid;

  GetTezosAddressEvent(this.uuid);
}

class TezosState {
  Map<String, String>? personaAddresses;
  Map<Network, Map<String, int>> balances;

  TezosState({
    this.personaAddresses,
    required Map<Network, Map<String, int>> balances,
  }) : this.balances = balances;

  TezosState copyWith({
    Map<String, String>? personaAddresses,
    Map<Network, Map<String, int>>? balances,
  }) {
    return TezosState(
      personaAddresses: personaAddresses ?? this.personaAddresses,
      balances: balances ?? this.balances,
    );
  }
}
