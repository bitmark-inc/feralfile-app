import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_dapp_service/wc_connected_session.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'accounts_state.dart';

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  ConfigurationService _configurationService;
  CloudDatabase _cloudDB;

  AccountsBloc(this._configurationService, this._cloudDB)
      : super(AccountsState()) {
    on<ResetEventEvent>((event, emit) async {
      emit(state.setEvent(null));
    });

    on<GetAccountsEvent>((event, emit) async {
      final personas = await _cloudDB.personaDao.getPersonas();
      final connections = await _cloudDB.connectionDao.getLinkedAccounts();

      List<Account> accounts = [];

      for (var persona in personas) {
        final ethAddress = await persona.wallet().getETHAddress();
        var name = await persona.wallet().getName();

        if (name.isEmpty) {
          name = persona.name;
        }

        final account = Account(
            persona: persona,
            name: name,
            accountNumber: ethAddress,
            createdAt: persona.createdAt);
        accounts.add(account);
      }

      for (var connection in connections) {
        switch (connection.connectionType) {
          case 'feralFileWeb3':
          case "feralFileToken":
            final source = connection.ffConnection?.source ??
                connection.ffWeb3Connection?.source;
            if (source == null) continue;

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
                    name: connection.name,
                    createdAt: connection.createdAt));
              }
            }
            break;

          default:
            accounts.add(Account(
              accountNumber: connection.accountNumber,
              connections: [connection],
              name: connection.name,
              createdAt: connection.createdAt,
            ));
            break;
        }
      }

      accounts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final network = _configurationService.getNetwork();
      emit(AccountsState(accounts: accounts, network: network));
    });

    on<GetCategorizedAccountsEvent>((event, emit) async {
      final personas = await _cloudDB.personaDao.getPersonas();
      final connections = await _cloudDB.connectionDao.getLinkedAccounts();

      List<CategorizedAccounts> categorizedAccounts = [
        CategorizedAccounts("Bitmark", []),
        CategorizedAccounts("Ethereum", []),
        CategorizedAccounts("Tezos", [])
      ];

      for (var persona in personas) {
        final ethAddress = await persona.wallet().getETHAddress();
        final xtzAddress = (await persona.wallet().getTezosWallet()).address;
        var name = await persona.wallet().getName();

        if (name.isEmpty) {
          name = persona.name;
        }

        final ethAccount = Account(
            persona: persona,
            name: name,
            blockchain: "Ethereum",
            accountNumber: ethAddress,
            createdAt: persona.createdAt);
        categorizedAccounts[1].accounts.add(ethAccount);

        final xtzAccount = Account(
            persona: persona,
            name: name,
            blockchain: "Tezos",
            accountNumber: xtzAddress,
            createdAt: persona.createdAt);
        categorizedAccounts[2].accounts.add(xtzAccount);
      }

      for (var connection in connections) {
        switch (connection.connectionType) {
          case "walletConnect":
            categorizedAccounts[1].accounts.add(Account(
                  blockchain: "Ethereum",
                  accountNumber: connection.accountNumber,
                  connections: [connection],
                  name: connection.name,
                  createdAt: connection.createdAt,
                ));
            break;
          case "walletBeacon":
            categorizedAccounts[2].accounts.add(Account(
                  blockchain: "Tezos",
                  accountNumber: connection.accountNumber,
                  connections: [connection],
                  name: connection.name,
                  createdAt: connection.createdAt,
                ));
            break;
          default:
            break;
        }
      }

      emit(state.copyWith(categorizedAccounts: categorizedAccounts));
    });

    on<LinkEthereumWalletEvent>((event, emit) async {
      final connection = Connection.fromETHWallet(event.session);
      final alreadyLinkedAccount =
          await getExistingAccount(connection.accountNumber);
      if (alreadyLinkedAccount != null) {
        emit(state.setEvent(AlreadyLinkedError(alreadyLinkedAccount)));
        return;
      }

      _cloudDB.connectionDao.insertConnection(connection);
      emit(state.setEvent(LinkAccountSuccess(connection)));

      add(GetAccountsEvent());
    });

    on<NameLinkedAccountEvent>((event, emit) {
      final connection = event.connection;
      connection.name = event.name;

      _cloudDB.connectionDao.updateConnection(connection);
      add(GetAccountsEvent());
    });

    on<DeleteLinkedAccountEvent>((event, emit) {
      final connection = event.connection;
      _cloudDB.connectionDao
          .deleteConnectionsByAccountNumber(connection.accountNumber);

      add(GetAccountsEvent());
    });

    on<FetchAllAddressesEvent>((event, emit) async {
      List<String> addresses = [];
      final personas = await _cloudDB.personaDao.getPersonas();

      for (var persona in personas) {
        final wallet = persona.wallet();
        final tzWallet = await wallet.getTezosWallet();
        final ethAddress = await wallet.getETHAddress();
        final tzAddress = tzWallet.address;

        addresses.add(ethAddress);
        addresses.add(tzAddress);
      }

      final linkedAccounts = await _cloudDB.connectionDao.getConnections();
      addresses.addAll(linkedAccounts.map((e) => e.accountNumber));
      addresses.removeWhere((e) => e == '');

      emit(state.setEvent(FetchAllAddressesSuccessEvent(addresses)));

      // reset the event after triggering
      await Future.delayed(Duration(milliseconds: 500), () {
        emit(state.setEvent(null));
      });
    });
  }

  Future<Connection?> getExistingAccount(String accountNumber) async {
    final existingConnections = await _cloudDB.connectionDao
        .getConnectionsByAccountNumber(accountNumber);

    if (existingConnections.isEmpty) return null;

    return existingConnections.first;
  }
}
