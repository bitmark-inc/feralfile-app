part of 'accounts_bloc.dart';

abstract class AccountsEvent {}

class ResetEventEvent extends AccountsEvent {}

class GetAccountsEvent extends AccountsEvent {}

class GetCategorizedAccountsEvent extends AccountsEvent {}

class LinkEthereumWalletEvent extends AccountsEvent {
  final WCConnectedSession session;

  LinkEthereumWalletEvent(this.session);
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
  Persona? persona;
  List<Connection>? connections;
  String name;
  String? blockchain;
  String accountNumber;
  DateTime createdAt;

  Account({
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

  CategorizedAccounts(this.category, this.accounts);
}

class AccountsState {
  List<Account>? accounts;
  List<CategorizedAccounts>? categorizedAccounts;
  Network? network;
  AccountBlocStateEvent? event;

  AccountsState(
      {this.accounts, this.categorizedAccounts, this.network, this.event});

  AccountsState copyWith(
      {List<Account>? accounts,
      List<CategorizedAccounts>? categorizedAccounts,
      Network? network,
      AccountBlocStateEvent? event}) {
    return AccountsState(
      accounts: accounts ?? this.accounts,
      categorizedAccounts: categorizedAccounts ?? this.categorizedAccounts,
      network: network ?? this.network,
      event: event ?? this.event,
    );
  }

  AccountsState setEvent(AccountBlocStateEvent? event) {
    return AccountsState(
      accounts: this.accounts,
      network: this.network,
      categorizedAccounts: this.categorizedAccounts,
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
