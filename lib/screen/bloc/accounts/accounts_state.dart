part of 'accounts_bloc.dart';

abstract class AccountsEvent {}

class GetAccountsEvent extends AccountsEvent {}

class Account {
  Persona? persona;
  List<Connection>? connections;
  String? name;
  ConnectionType? type;
  String accountNumber;
  DateTime createdAt;

  Account({
    this.persona,
    this.connections,
    this.accountNumber = "",
    this.name,
    this.type,
    required this.createdAt,
  });
}

class AccountsState {
  List<Account>? accounts;
  Network? network;

  AccountsState({this.accounts, this.network});
}
