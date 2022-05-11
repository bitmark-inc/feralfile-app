import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/aws_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'accounts_state.dart';

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  ConfigurationService _configurationService;
  CloudDatabase _cloudDB;
  BackupService _backupService;
  AuditService _auditService;
  AccountService _accountService;

  AccountsBloc(this._configurationService, this._cloudDB, this._backupService,
      this._auditService, this._accountService)
      : super(AccountsState()) {
    on<ResetEventEvent>((event, emit) async {
      emit(state.setEvent(null));
    });

    on<GetAccountsEvent>((event, emit) async {
      final personas = await _cloudDB.personaDao.getPersonas();
      final connections = await _cloudDB.connectionDao.getLinkedAccounts();

      List<Account> accounts = [];

      for (var persona in personas) {
        final ethAddress = await persona.wallet().getETHEip55Address();
        if (ethAddress.isEmpty) continue;
        var name = await persona.wallet().getName();

        if (name.isEmpty) {
          name = persona.name;
        }

        final account = Account(
            key: persona.uuid,
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
                    key: connection.key,
                    accountNumber: accountNumber,
                    connections: [connection],
                    name: connection.name,
                    createdAt: connection.createdAt));
              }
            }
            break;

          default:
            accounts.add(Account(
              key: connection.key,
              accountNumber: connection.accountNumber,
              connections: [connection],
              name: connection.name,
              createdAt: connection.createdAt,
            ));
            break;
        }
      }

      if (accounts.isEmpty) {
        await _backupService
            .deleteAllProfiles(await _accountService.getDefaultAccount());
        await _cloudDB.personaDao.removeAll();
        await _cloudDB.connectionDao.removeAll();
        await _auditService.audiPersonaAction('cleanUp', null);
      }

      accounts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final network = _configurationService.getNetwork();
      emit(AccountsState(accounts: accounts, network: network));
    });

    on<GetCategorizedAccountsEvent>((event, emit) async {
      final personas = await _cloudDB.personaDao.getPersonas();
      final connections = await _cloudDB.connectionDao.getLinkedAccounts();

      List<CategorizedAccounts> categorizedAccounts = [];

      for (var persona in personas) {
        final bitmarkAddress = await persona.wallet().getBitmarkAddress();
        final ethAddress = await persona.wallet().getETHEip55Address();
        final xtzAddress = (await persona.wallet().getTezosWallet()).address;
        var name = await persona.wallet().getName();

        if (name.isEmpty) {
          name = persona.name;
        }

        final bitmarkAccount = Account(
            key: persona.uuid,
            persona: persona,
            name: name,
            blockchain: "Bitmark",
            accountNumber: bitmarkAddress,
            createdAt: persona.createdAt);

        final ethAccount = Account(
            key: persona.uuid,
            persona: persona,
            name: name,
            blockchain: "Ethereum",
            accountNumber: ethAddress,
            createdAt: persona.createdAt);

        final xtzAccount = Account(
            key: persona.uuid,
            persona: persona,
            name: name,
            blockchain: "Tezos",
            accountNumber: xtzAddress,
            createdAt: persona.createdAt);

        categorizedAccounts.add(CategorizedAccounts(
            name, [bitmarkAccount, ethAccount, xtzAccount]));
      }

      for (var connection in connections) {
        switch (connection.connectionType) {
          case "walletConnect":
          case "ledgerEthereum":
            categorizedAccounts.add(CategorizedAccounts(connection.name, [
              Account(
                key: connection.key,
                blockchain: "Ethereum",
                accountNumber: connection.accountNumber,
                connections: [connection],
                name: connection.name,
                createdAt: connection.createdAt,
              )
            ]));
            break;
          case "walletBeacon":
          case "ledgerTezos":
            categorizedAccounts.add(CategorizedAccounts(connection.name, [
              Account(
                key: connection.key,
                blockchain: "Tezos",
                accountNumber: connection.accountNumber,
                connections: [connection],
                name: connection.name,
                createdAt: connection.createdAt,
              )
            ]));
            break;
          default:
            break;
        }
      }

      emit(state.copyWith(categorizedAccounts: categorizedAccounts));
    });

    on<LinkLedgerWalletEvent>((event, emit) async {
      final data = event.data;
      data["ledger"] = event.ledgerName;
      data["ledger_uuid"] = event.ledgerBLEUUID;

      late Connection connection;
      switch (event.blockchain) {
        case "Ethereum":
          connection = Connection.fromLedgerEthereumWallet(event.address, data);
          break;
        case "Tezos":
          connection = Connection.fromLedgerTezosWallet(event.address, data);
          break;
        default:
          throw "Unhandled blockchain ${event.blockchain}";
      }
      final alreadyLinkedAccount = await getExistingAccount(event.address);
      if (alreadyLinkedAccount != null) {
        emit(state.setEvent(AlreadyLinkedError(alreadyLinkedAccount)));
        return;
      }

      _cloudDB.connectionDao.insertConnection(connection);
      emit(state.setEvent(LinkAccountSuccess(connection)));

      injector<AWSService>().storeEventWithDeviceData(
        "link_ledger",
        data: {"blockchain": event.blockchain},
        hashingData: {"address": event.address},
      );

      add(GetAccountsEvent());
    });

    on<NameLinkedAccountEvent>((event, emit) {
      final connection = event.connection;
      connection.name = event.name;

      _cloudDB.connectionDao.updateConnection(connection);
      add(GetAccountsEvent());
    });

    on<FetchAllAddressesEvent>((event, emit) async {
      List<String> addresses = [];
      if (_configurationService.isDemoArtworksMode()) {
        addresses = [await getDemoAccount()];
      } else {
        final personas = await _cloudDB.personaDao.getPersonas();

        for (var persona in personas) {
          final wallet = persona.wallet();
          final tzWallet = await wallet.getTezosWallet();
          final ethAddress = await wallet.getETHEip55Address();
          final tzAddress = tzWallet.address;

          addresses.add(ethAddress);
          addresses.add(tzAddress);
        }

        final linkedAccounts = await _cloudDB.connectionDao.getConnections();
        addresses.addAll(linkedAccounts.map((e) => e.accountNumber));
        addresses.removeWhere((e) => e == '');
      }

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
