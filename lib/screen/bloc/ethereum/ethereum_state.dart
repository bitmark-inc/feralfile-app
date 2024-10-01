//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

part of 'ethereum_bloc.dart';

abstract class EthereumEvent {}

class GetEthereumBalanceWithAddressEvent extends EthereumEvent {
  final List<String> addresses;

  GetEthereumBalanceWithAddressEvent(this.addresses);
}

class GetEthereumBalanceWithUUIDEvent extends EthereumEvent {
  final String uuid;

  GetEthereumBalanceWithUUIDEvent(this.uuid);
}

class GetEthereumAddressEvent extends EthereumEvent {
  final String uuid;

  GetEthereumAddressEvent(this.uuid);
}

class EthereumState {
  Map<String, List<WalletAddress>>? walletAddresses;
  Map<String, EtherAmount> ethBalances;

  EthereumState(this.walletAddresses, this.ethBalances);

  EthereumState copyWith({
    Map<String, List<WalletAddress>>? walletAddresses,
    Map<String, EtherAmount>? ethBalances,
  }) =>
      EthereumState(
        walletAddresses ?? this.walletAddresses,
        ethBalances ?? this.ethBalances,
      );
}
