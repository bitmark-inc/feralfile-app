import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'accounts_state.dart';

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  ConfigurationService _configurationService;
  CloudDatabase _cloudDB;

  AccountsBloc(this._configurationService, this._cloudDB)
      : super(AccountsState()) {
    on<GetAccountsEvent>((event, emit) async {
      final personas = await _cloudDB.personaDao.getPersonas();
      final connections = await _cloudDB.connectionDao.getConnections();

      List<Account> accounts = [];

      for (var persona in personas) {
        final ethAddress = await persona.wallet().getETHAddress();
        final account = Account(
            persona: persona,
            accountNumber: ethAddress,
            createdAt: persona.createdAt);
        accounts.add(account);
      }

      for (var connection in connections) {
        final source = connection.ffConnection?.source;
        if (source == null) break;
        if (_configurationService.matchFeralFileSourceInNetwork(source)) {
          final accountNumber = connection.accountNumber;
          try {
            final account = accounts.firstWhere(
                (element) => element.accountNumber == accountNumber);
            account.connections?.add(connection);
          } catch (error) {
            accounts.add(Account(
                accountNumber: accountNumber,
                connections: [connection],
                createdAt: connection.createdAt));
          }
        }
      }

      accounts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final network = _configurationService.getNetwork();
      emit(AccountsState(accounts: accounts, network: network));
    });
  }
}
