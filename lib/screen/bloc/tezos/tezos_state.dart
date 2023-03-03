//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

part of 'tezos_bloc.dart';

abstract class TezosEvent {}

class GetTezosBalanceWithAddressEvent extends TezosEvent {
  final List<String> addresses;

  GetTezosBalanceWithAddressEvent(this.addresses);
}

class GetTezosBalanceWithUUIDEvent extends TezosEvent {
  final String uuid;

  GetTezosBalanceWithUUIDEvent(this.uuid);
}

class GetTezosAddressEvent extends TezosEvent {
  final String uuid;

  GetTezosAddressEvent(this.uuid);
}

class TezosState {
  Map<String, List<String>>? personaAddresses;
  Map<String, int> balances;

  TezosState(this.personaAddresses, this.balances);

  TezosState copyWith({
    Map<String, List<String>>? personaAddresses,
    Map<String, int>? balances,
  }) {
    return TezosState(
      personaAddresses ?? this.personaAddresses,
      balances ?? this.balances,
    );
  }
}
