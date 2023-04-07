//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/model/connection_supports.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/screen/onboarding_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

part 'accounts_state.dart';

class AccountsBloc extends AuBloc<AccountsEvent, AccountsState> {
  final ConfigurationService _configurationService;
  final CloudDatabase _cloudDB;
  final BackupService _backupService;
  final AuditService _auditService;
  final AccountService _accountService;

  AccountsBloc(this._configurationService, this._cloudDB, this._backupService,
      this._auditService, this._accountService)
      : super(AccountsState()) {
    on<ResetEventEvent>((event, emit) async {
      emit(state.setEvent(null));
    });

    on<GetAccountsEvent>((event, emit) async {
      final connectionsFuture =
          _cloudDB.connectionDao.getUpdatedLinkedAccounts();
      final personas = await _cloudDB.personaDao.getPersonas();

      List<Account> accounts = (await Future.wait(
              personas.map((persona) => getAccountPersona(persona))))
          .whereNotNull()
          .toList();

      final connections = await connectionsFuture;
      for (var connection in connections) {
        switch (connection.connectionType) {
          case 'feralFileWeb3':
          case "feralFileToken":
            final source = connection.ffConnection?.source ??
                connection.ffWeb3Connection?.source;
            if (source == null) continue;

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
        await _auditService.auditPersonaAction('cleanUp', null);
      }

      accounts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final defaultAccount = accounts.firstWhereOrNull((element) =>
          element.persona != null ? element.persona!.isDefault() : false);
      if (defaultAccount != null) {
        accounts.remove(defaultAccount);
        accounts.insert(0, defaultAccount);
      }
      emit(AccountsState(accounts: accounts));
    });

    on<GetAccountsIRLEvent>((event, emit) async {
      final personas = await _cloudDB.personaDao.getPersonas();

      List<Account> accounts = (await Future.wait(
              personas.map((persona) => getAccountPersona(persona))))
          .whereNotNull()
          .toList();

      accounts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final defaultAccount = accounts.firstWhereOrNull((element) =>
          element.persona != null ? element.persona!.isDefault() : false);
      if (defaultAccount != null) {
        accounts.remove(defaultAccount);
        accounts.insert(0, defaultAccount);
      }
      emit(AccountsState(accounts: accounts));
    });

    on<GetCategorizedAccountsEvent>((event, emit) async {
      final personas = await _cloudDB.personaDao.getPersonas();
      final connections =
          await _cloudDB.connectionDao.getUpdatedLinkedAccounts();
      logger.info(
          'GetCategorizedAccountsEvent: personas: ${personas.map((e) => e.uuid).toList()}');
      if (personas.isEmpty &&
          ((event.includeLinkedAccount && connections.isEmpty) ||
              !event.includeLinkedAccount)) {
        emit(state.copyWith(categorizedAccounts: []));
      }
      List<CategorizedAccounts> categorizedAccounts = [];

      for (var persona in personas) {
        if (!await persona.wallet().isWalletCreated()) continue;
        final ethAddresses = await persona.getEthAddresses();
        final xtzAddresses = await persona.getTezosAddresses();
        var name = await persona.wallet().getName();

        if (name.isEmpty) {
          name = persona.name.isNotEmpty
              ? persona.name
              : (await persona.wallet().getAccountDID())
                  .replaceFirst('did:key:', '');
        }

        final List<Account> accounts = [];
        final List<Account> ethAccounts = [];
        final List<Account> xtzAccounts = [];
        for (var address in ethAddresses) {
          final ethAccount = Account(
              key: persona.uuid,
              persona: persona,
              name: name,
              blockchain: "Ethereum",
              accountNumber: address,
              createdAt: persona.createdAt);
          ethAccounts.add(ethAccount);
        }
        for (var address in xtzAddresses) {
          final xtzAccount = Account(
              key: persona.uuid,
              persona: persona,
              name: name,
              blockchain: "Tezos",
              accountNumber: address,
              createdAt: persona.createdAt);
          xtzAccounts.add(xtzAccount);
        }
        if (event.getEth && ethAccounts.isNotEmpty) {
          accounts.addAll(ethAccounts);
        }

        if (event.getTezos && xtzAccounts.isNotEmpty) {
          accounts.addAll(xtzAccounts);
        }
        if (accounts.isNotEmpty) {
          categorizedAccounts.add(
            CategorizedAccounts(
              name,
              accounts,
              'Persona',
            ),
          );
        }
      }

      if (event.includeLinkedAccount) {
        for (var connection in connections) {
          switch (connection.connectionType) {
            case "walletConnect":
            case "walletBrowserConnect":
              if (event.getEth) {
                categorizedAccounts.add(
                  CategorizedAccounts(
                    connection.name,
                    [
                      Account(
                        key: connection.key,
                        blockchain: "Ethereum",
                        accountNumber: connection.accountNumber,
                        connections: [connection],
                        name: connection.name,
                        createdAt: connection.createdAt,
                      )
                    ],
                    'Connection',
                  ),
                );
              }
              break;
            case "walletBeacon":
              if (event.getTezos) {
                categorizedAccounts.add(
                  CategorizedAccounts(
                    connection.name,
                    [
                      Account(
                        key: connection.key,
                        blockchain: "Tezos",
                        accountNumber: connection.accountNumber,
                        connections: [connection],
                        name: connection.name,
                        createdAt: connection.createdAt,
                      )
                    ],
                    'Connection',
                  ),
                );
              }
              break;

            case 'ledger':
              final data = connection.ledgerConnection;
              List<Account> accounts = [];

              final ethereumAddresses = data?.etheremAddress ?? [];
              final tezosAddresses = data?.tezosAddress ?? [];

              for (final ethereumAddress in ethereumAddresses) {
                if (event.getEth) {
                  accounts.add(
                    Account(
                      key: connection.key + ethereumAddress,
                      blockchain: "Ethereum",
                      accountNumber: ethereumAddress,
                      connections: [connection],
                      name: connection.name,
                      createdAt: connection.createdAt,
                    ),
                  );
                }
              }

              for (final tezosAddress in tezosAddresses) {
                if (event.getTezos) {
                  accounts.add(
                    Account(
                      key: connection.key + tezosAddress,
                      blockchain: "Tezos",
                      accountNumber: tezosAddress,
                      connections: [connection],
                      name: connection.name,
                      createdAt: connection.createdAt,
                    ),
                  );
                }
              }

              if (accounts.isNotEmpty) {
                categorizedAccounts.add(CategorizedAccounts(
                  connection.name,
                  accounts,
                  'Connection',
                ));
              }
              break;

            default:
              break;
          }
        }
      }

      emit(state.copyWith(categorizedAccounts: categorizedAccounts));
    });

    on<LinkLedgerWalletEvent>((event, emit) async {
      var connection =
          await _cloudDB.connectionDao.findById(event.ledgerBLEUUID);
      if (connection != null &&
          connection.accountNumber.contains(event.address)) {
        emit(state.setEvent(AlreadyLinkedError(connection)));
        return;
      }

      var data = LedgerConnection(
          ledgerName: event.ledgerName,
          ledgerUUID: event.ledgerBLEUUID,
          etheremAddress: [],
          tezosAddress: []);

      if (connection != null) {
        data = LedgerConnection.fromJson(json.decode(connection.data));
      }

      switch (event.blockchain) {
        case "Ethereum":
          data.etheremAddress.add(event.address.getETHEip55Address());
          break;
        case "Tezos":
          data.tezosAddress.add(event.address);
          break;
        default:
          throw "Unhandled blockchain ${event.blockchain}";
      }

      final newConnection = Connection(
        key: event.ledgerBLEUUID,
        name: connection?.name ?? event.ledgerName,
        data: json.encode(data),
        connectionType: ConnectionType.ledger.rawValue,
        accountNumber:
            ((connection?.accountNumbers ?? []) + [event.address]).join("||"),
        createdAt: connection?.createdAt ?? DateTime.now(),
      );

      _cloudDB.connectionDao.insertConnection(newConnection);
      emit(state.setEvent(LinkAccountSuccess(newConnection)));

      final metricClient = injector.get<MetricClientService>();

      metricClient.addEvent(
        MixpanelEvent.linkLedger,
        data: {"blockchain": event.blockchain},
        hashedData: {"address": event.address},
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
          addresses.addAll(await persona.getAddresses());
        }

        final linkedAccounts = await _cloudDB.connectionDao.getConnections();
        addresses.addAll(linkedAccounts.expand((e) => e.accountNumbers));
        addresses.removeWhere((e) => e == '');
      }

      final newState = state.copyWith(
          addresses: addresses,
          event: FetchAllAddressesSuccessEvent(addresses));
      emit(newState);

      // reset the event after triggering
      await Future.delayed(const Duration(milliseconds: 500), () {
        emit(newState.setEvent(null));
      });
    });

    on<FindAccount>((event, emit) async {
      final persona = await _cloudDB.personaDao.findById(event.personaUUID);
      List<Account> accounts = [];
      if (persona != null) {
        accounts.add(Account(
            key: persona.uuid,
            persona: persona,
            name: persona.name,
            blockchain: event.type.source,
            accountNumber: event.address,
            createdAt: persona.createdAt));
      }
      emit(AccountsState(accounts: accounts));
    });
  }

  Future<Connection?> getExistingAccount(String accountNumber) async {
    final existingConnections = await _cloudDB.connectionDao
        .getConnectionsByAccountNumber(accountNumber);

    if (existingConnections.isEmpty) return null;

    return existingConnections.first;
  }

  Future<Account?> getAccountPersona(Persona persona) async {
    final nameFuture = persona.wallet().getName();
    final ethAddress = await persona.wallet().getETHEip55Address();
    if (ethAddress.isEmpty) return null;
    var name = await nameFuture;

    if (name.isEmpty) {
      name = persona.name;
    }

    final account = Account(
        key: persona.uuid,
        persona: persona,
        name: name,
        accountNumber: ethAddress,
        createdAt: persona.createdAt);
    return account;
  }
}
