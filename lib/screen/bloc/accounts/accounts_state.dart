part of 'accounts_bloc.dart';

abstract class AccountsEvent {}

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

class DeleteLinkedAccountEvent extends AccountsEvent {
  final Connection connection;

  DeleteLinkedAccountEvent(this.connection);
}

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

  Connection? justLinkedAccount;

  AccountsState(
      {this.accounts,
      this.categorizedAccounts,
      this.network,
      this.justLinkedAccount});

  AccountsState copyWith({
    List<Account>? accounts,
    Network? network,
    Connection? justLinkedAccount,
  }) {
    return AccountsState(
      accounts: accounts ?? this.accounts,
      network: network ?? this.network,
      justLinkedAccount: justLinkedAccount ?? this.justLinkedAccount,
    );
  }

  AccountsState resetLinkedAccountState() {
    return AccountsState(
        accounts: this.accounts,
        network: this.network,
        justLinkedAccount: null);
  }
}
