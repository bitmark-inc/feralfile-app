part of 'ethereum_bloc.dart';

abstract class EthereumEvent {}

class GetEthereumBalanceWithAddressEvent extends EthereumEvent {
  final String address;

  GetEthereumBalanceWithAddressEvent(this.address);
}

class GetEthereumBalanceWithUUIDEvent extends EthereumEvent {
  final String uuid;

  GetEthereumBalanceWithUUIDEvent(this.uuid);
}

class GetEthereumAddressEvent extends EthereumEvent {
  final String uuid;

  GetEthereumAddressEvent(this.uuid);
}

class EthereumState {
  Map<String, String>? personaAddresses;
  Map<Network, Map<String, EtherAmount>> ethBalances;

  EthereumState({
    this.personaAddresses,
    required Map<Network, Map<String, EtherAmount>> ethBalances,
  }) : this.ethBalances = ethBalances;

  EthereumState copyWith({
    Map<String, String>? personaAddresses,
    Map<Network, Map<String, EtherAmount>>? ethBalances,
  }) {
    return EthereumState(
      personaAddresses: personaAddresses ?? this.personaAddresses,
      ethBalances: ethBalances ?? this.ethBalances,
    );
  }
}
