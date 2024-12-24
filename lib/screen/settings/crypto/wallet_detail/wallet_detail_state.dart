//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/wallet_address.dart';
import 'package:autonomy_flutter/util/constants.dart';

abstract class WalletDetailEvent {}

class WalletDetailBalanceEvent extends WalletDetailEvent {
  CryptoType type;
  String address;

  WalletDetailBalanceEvent(this.type, this.address);
}

class WalletDetailPrimaryAddressEvent extends WalletDetailEvent {
  WalletAddress walletAddress;

  WalletDetailPrimaryAddressEvent(this.walletAddress);
}

class WalletDetailState {
  final String balance;
  final String balanceInUSD;
  final bool isPrimary;

  WalletDetailState({
    this.balance = '',
    this.balanceInUSD = '',
    this.isPrimary = false,
  });

  WalletDetailState copyWith({
    String? balance,
    String? balanceInUSD,
    bool? isPrimary,
  }) =>
      WalletDetailState(
        balance: balance ?? this.balance,
        balanceInUSD: balanceInUSD ?? this.balanceInUSD,
        isPrimary: isPrimary ?? this.isPrimary,
      );
}
