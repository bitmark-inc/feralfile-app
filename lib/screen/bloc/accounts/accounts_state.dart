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

class GetCategorizedAccountsEvent extends AccountsEvent {}

class LinkLedgerWalletEvent extends AccountsEvent {
  final String address;
  final String blockchain;
  final String ledgerName;
  final String ledgerBLEUUID;
  final Map<String, dynamic> data;

  LinkLedgerWalletEvent(this.address, this.blockchain, this.ledgerName,
      this.ledgerBLEUUID, this.data);
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

class Account {
  String key;
  Persona? persona;
  List<Connection>? connections;
  String name;
  String? blockchain;
  String accountNumber;
  DateTime createdAt;

  Account({
    required this.key,
    this.persona,
    this.connections,
    this.blockchain,
    this.accountNumber = "",
    this.name = "",
    required this.createdAt,
  });
}

class CategorizedAccounts {
  String category;
  List<Account> accounts;
  String className;

  CategorizedAccounts(this.category, this.accounts, this.className);
}

class AccountsState {
  List<String> addresses;
  List<Account>? accounts;
  List<CategorizedAccounts>? categorizedAccounts;
  AccountBlocStateEvent? event;

  AccountsState(
      {this.addresses = const [],
      this.accounts,
      this.categorizedAccounts,
      this.event});

  AccountsState copyWith(
      {List<String>? addresses,
      List<Account>? accounts,
      List<CategorizedAccounts>? categorizedAccounts,
      Network? network,
      AccountBlocStateEvent? event}) {
    return AccountsState(
      addresses: addresses ?? this.addresses,
      accounts: accounts ?? this.accounts,
      categorizedAccounts: categorizedAccounts ?? this.categorizedAccounts,
      event: event ?? this.event,
    );
  }

  AccountsState setEvent(AccountBlocStateEvent? event) {
    return AccountsState(
      addresses: addresses,
      accounts: accounts,
      categorizedAccounts: categorizedAccounts,
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
