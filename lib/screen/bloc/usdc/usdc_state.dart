//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

part of 'usdc_bloc.dart';

abstract class USDCEvent {}

class GetUSDCBalanceWithAddressEvent extends USDCEvent {
  final String address;

  GetUSDCBalanceWithAddressEvent(this.address);
}

class GetUSDCBalanceWithUUIDEvent extends USDCEvent {
  final String uuid;
  final int index;

  GetUSDCBalanceWithUUIDEvent(this.uuid, this.index);
}

class GetAddressEvent extends USDCEvent {
  final String uuid;
  final int index;

  GetAddressEvent(this.uuid, this.index);
}

class USDCState {
  Map<String, String>? walletAddresses;
  Map<String, BigInt> usdcBalances;

  USDCState(this.walletAddresses, this.usdcBalances);

  USDCState copyWith({
    Map<String, String>? walletAddresses,
    Map<String, BigInt>? usdcBalances,
  }) =>
      USDCState(
        walletAddresses ?? this.walletAddresses,
        usdcBalances ?? this.usdcBalances,
      );
}
