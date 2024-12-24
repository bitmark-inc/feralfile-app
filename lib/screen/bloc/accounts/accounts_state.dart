//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/wallet_address.dart';

abstract class AccountsEvent {}

class GetAccountsEvent extends AccountsEvent {}

class ChangeAccountOrderEvent extends AccountsEvent {
  ChangeAccountOrderEvent({required this.oldOrder, required this.newOrder});

  final int oldOrder;
  final int newOrder;
}

class FetchAllAddressesEvent extends AccountsEvent {}

class AccountsState {
  AccountsState({
    this.addresses,
  });

  List<WalletAddress>? addresses;

  AccountsState copyWith({
    List<WalletAddress>? addresses,
  }) =>
      AccountsState(
        addresses: addresses ?? this.addresses,
      );
}

abstract class AccountBlocStateEvent {}

class FetchAllAddressesSuccessEvent extends AccountBlocStateEvent {
  FetchAllAddressesSuccessEvent(this.addresses);

  final List<String> addresses;
}
