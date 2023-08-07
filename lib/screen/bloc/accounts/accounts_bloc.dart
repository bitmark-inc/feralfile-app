//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

part 'accounts_state.dart';

class AccountsBloc extends AuBloc<AccountsEvent, AccountsState> {
  final ConfigurationService _configurationService;
  final CloudDatabase _cloudDB;

  AccountsBloc(this._configurationService, this._cloudDB)
      : super(AccountsState()) {
    on<ResetEventEvent>((event, emit) async {
      emit(state.setEvent(null));
    });

    on<GetAccountsEvent>((event, emit) async {
      final connectionsFuture =
          _cloudDB.connectionDao.getUpdatedLinkedAccounts();
      final addresses = await _cloudDB.addressDao.getAllAddresses();

      List<Account> accounts = await getAccountPersona(addresses);

      final connections = await connectionsFuture;
      for (var connection in connections) {
        accounts.add(_getAccountFromConnectionAddress(
            connection, connection.accountNumber));
      }

      accounts.sort(_compareAccount);

      emit(AccountsState(accounts: accounts));
    });

    on<GetAccountsIRLEvent>((event, emit) async {
      final addresses = await _cloudDB.addressDao.getAllAddresses();

      List<Account> accounts = await getAccountPersona(addresses);

      accounts.sort(_compareAccount);
      emit(AccountsState(accounts: accounts));
    });

    on<GetCategorizedAccountsEvent>((event, emit) async {
      late List<WalletAddress> addresses;
      final type =
          WalletType.getWallet(eth: event.getEth, tezos: event.getTezos);
      switch (type) {
        case WalletType.Autonomy:
          addresses = await _cloudDB.addressDao.getAllAddresses();
          break;
        case WalletType.Ethereum:
          addresses = await _cloudDB.addressDao
              .getAddressesByType(CryptoType.ETH.source);
          break;
        case WalletType.Tezos:
          addresses = await _cloudDB.addressDao
              .getAddressesByType(CryptoType.XTZ.source);
          break;
        default:
          addresses = [];
      }
      if (event.autoAddAddress) {
        final persona =
            await injector<AccountService>().getOrCreateDefaultPersona();
        if (event.getEth &&
            addresses.none(
                (element) => element.cryptoType == CryptoType.ETH.source)) {
          final ethAddress =
              await persona.insertNextAddress(WalletType.Ethereum);
          addresses.add(ethAddress.first);
        }
        if (event.getTezos &&
            addresses.none(
                (element) => element.cryptoType == CryptoType.XTZ.source)) {
          final tezosAddress =
              await persona.insertNextAddress(WalletType.Tezos);
          addresses.add(tezosAddress.first);
        }
      }

      List<Account> accounts = await getAccountPersona(addresses);
      accounts.sort(_compareAccount);
      emit(state.copyWith(accounts: accounts));
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

    on<FindLinkedAccount>((event, emit) async {
      final connection =
          await _cloudDB.connectionDao.findById(event.connectionKey);
      List<Account> accounts = [];
      if (connection != null) {
        accounts.add(Account(
            key: connection.key,
            name: connection.name,
            blockchain: event.type.source,
            accountNumber: event.address,
            connections: [connection],
            createdAt: connection.createdAt));
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

  Future<List<Account>> getAccountPersona(
      List<WalletAddress> walletAddresses) async {
    final personas = await _cloudDB.personaDao.getPersonas();
    final List<WalletAddress> addresses = [];
    addresses.addAll(walletAddresses);
    List<Account> accounts = [];
    for (var e in addresses) {
      final name = e.name != null && e.name!.isNotEmpty ? e.name : e.cryptoType;
      final persona =
          personas.firstWhereOrNull((element) => element.uuid == e.uuid);
      if (persona != null) {
        accounts.add(Account(
            key: e.address,
            persona: persona,
            name: name ?? "",
            blockchain: e.cryptoType,
            walletAddress: e,
            accountNumber: e.address,
            createdAt: e.createdAt));
      }
    }
    return accounts;
  }

  int _compareAccount(Account a, Account b) {
    final aDefault = a.persona?.defaultAccount ?? 0;
    final bDefault = b.persona?.defaultAccount ?? 0;
    if (aDefault != bDefault) {
      return bDefault.compareTo(aDefault);
    }
    return a.createdAt.compareTo(b.createdAt);
  }

  Account _getAccountFromConnectionAddress(
      Connection connection, String address) {
    final cryptoType = CryptoType.fromAddress(address).source;
    final name = connection.name.isNotEmpty ? connection.name : cryptoType;
    return Account(
      key: connection.key,
      accountNumber: address,
      connections: [connection],
      blockchain: cryptoType,
      name: name,
      createdAt: connection.createdAt,
    );
  }
}
