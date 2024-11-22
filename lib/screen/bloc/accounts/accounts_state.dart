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

class ChangeAccountOrderEvent extends AccountsEvent {
  final int oldOrder;
  final int newOrder;

  ChangeAccountOrderEvent({required this.oldOrder, required this.newOrder});
}

class SaveAccountOrderEvent extends AccountsEvent {
  final List<Account> accounts;

  SaveAccountOrderEvent({required this.accounts});
}

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

class FetchAllAddressesEvent extends AccountsEvent {}

class Account {
  String key;
  String name;
  String? blockchain;
  WalletAddress? walletAddress;
  String accountNumber;
  DateTime createdAt;
  int? accountOrder;

  bool get isTez => blockchain == 'Tezos';

  bool get isEth => blockchain == 'Ethereum';

  bool get isUsdc => blockchain == 'USDC';

  bool get isViewOnly => walletAddress == null;

  Account({
    required this.key,
    required this.createdAt,
    this.blockchain,
    this.walletAddress,
    this.accountNumber = '',
    this.name = '',
    this.accountOrder,
  });

  @override
  bool operator ==(covariant Account other) {
    if (identical(this, other)) {
      return true;
    }

    return other.key == key &&
        other.name == name &&
        other.blockchain == blockchain &&
        other.walletAddress == walletAddress &&
        other.accountNumber == accountNumber &&
        other.createdAt == createdAt &&
        other.accountOrder == accountOrder;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      name.hashCode ^
      blockchain.hashCode ^
      walletAddress.hashCode ^
      accountNumber.hashCode ^
      createdAt.hashCode ^
      accountOrder.hashCode;
}

class AccountsState {
  List<String> addresses;
  List<Account>? accounts;
  AddressInfo? primaryAddressInfo;
  AccountBlocStateEvent? event;

  AccountsState({
    this.addresses = const [],
    this.accounts,
    this.event,
    this.primaryAddressInfo,
  });

  AccountsState copyWith(
          {List<String>? addresses,
          List<Account>? accounts,
          AddressInfo? primaryAddressInfo,
          Network? network,
          AccountBlocStateEvent? event}) =>
      AccountsState(
        addresses: addresses ?? this.addresses,
        accounts: accounts ?? this.accounts,
        primaryAddressInfo: primaryAddressInfo ?? this.primaryAddressInfo,
        event: event ?? this.event,
      );

  AccountsState setEvent(AccountBlocStateEvent? event) => AccountsState(
        addresses: addresses,
        accounts: accounts,
        primaryAddressInfo: primaryAddressInfo,
        event: event,
      );
}

abstract class AccountBlocStateEvent {}

class FetchAllAddressesSuccessEvent extends AccountBlocStateEvent {
  final List<String> addresses;

  FetchAllAddressesSuccessEvent(this.addresses);
}
