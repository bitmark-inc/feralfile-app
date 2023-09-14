//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

part of 'accounts_bloc.dart';

abstract class AccountsEvent {}

class ResetEventEvent extends AccountsEvent {}

class GetAccountsEvent extends AccountsEvent {}

class GetCategorizedAccountsEvent extends AccountsEvent {
  final bool includeLinkedAccount;
  final bool getTezos;
  final bool getEth;
  final bool autoAddAddress;

  GetCategorizedAccountsEvent({
    this.includeLinkedAccount = false,
    this.getTezos = true,
    this.getEth = true,
    this.autoAddAddress = false,
  });
}

class GetAccountsIRLEvent extends AccountsEvent {
  final Map<String, dynamic>? param;
  final String? blockchain;

  GetAccountsIRLEvent({this.param, this.blockchain});
}

class NameLinkedAccountEvent extends AccountsEvent {
  final Connection connection;
  final String name;

  NameLinkedAccountEvent(
    this.connection,
    this.name,
  );
}

class FetchAllAddressesEvent extends AccountsEvent {}

class FindAccount extends AccountsEvent {
  final String personaUUID;
  final String address;
  final CryptoType type;

  FindAccount(this.personaUUID, this.address, this.type);
}

class FindLinkedAccount extends AccountsEvent {
  final String connectionKey;
  final String address;
  final CryptoType type;

  FindLinkedAccount(this.connectionKey, this.address, this.type);
}

class Account {
  String key;
  Persona? persona;
  List<Connection>? connections;
  String name;
  String? blockchain;
  WalletAddress? walletAddress;
  String accountNumber;
  DateTime createdAt;

  bool get isTez => blockchain == "Tezos";

  bool get isEth => blockchain == "Ethereum";

  bool get isUsdc => blockchain == "USDC";

  String get className =>
      persona != null && walletAddress != null ? "Persona" : "Connection";

  Account({
    required this.key,
    this.persona,
    this.connections,
    this.blockchain,
    this.walletAddress,
    this.accountNumber = "",
    this.name = "",
    required this.createdAt,
  });

  @override
  bool operator ==(covariant Account other) {
    if (identical(this, other)) return true;

    return other.key == key &&
        other.persona == persona &&
        listEquals(other.connections, connections) &&
        other.name == name &&
        other.blockchain == blockchain &&
        other.walletAddress == walletAddress &&
        other.accountNumber == accountNumber &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return key.hashCode ^
        persona.hashCode ^
        connections.hashCode ^
        name.hashCode ^
        blockchain.hashCode ^
        walletAddress.hashCode ^
        accountNumber.hashCode ^
        createdAt.hashCode;
  }
}

class AccountsState {
  List<String> addresses;
  List<Account>? accounts;
  AccountBlocStateEvent? event;

  AccountsState({this.addresses = const [], this.accounts, this.event});

  AccountsState copyWith(
      {List<String>? addresses,
      List<Account>? accounts,
      Network? network,
      AccountBlocStateEvent? event}) {
    return AccountsState(
      addresses: addresses ?? this.addresses,
      accounts: accounts ?? this.accounts,
      event: event ?? this.event,
    );
  }

  AccountsState setEvent(AccountBlocStateEvent? event) {
    return AccountsState(
      addresses: addresses,
      accounts: accounts,
      event: event,
    );
  }
}

abstract class AccountBlocStateEvent {}

class LinkAccountSuccess extends AccountBlocStateEvent {
  final Connection connection;

  LinkAccountSuccess(this.connection);
}

class AlreadyLinkedError extends AccountBlocStateEvent {
  final Connection connection;

  AlreadyLinkedError(this.connection);
}

class FetchAllAddressesSuccessEvent extends AccountBlocStateEvent {
  final List<String> addresses;

  FetchAllAddressesSuccessEvent(this.addresses);
}
