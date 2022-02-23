import 'package:libauk_dart/libauk_dart.dart';

import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_page.dart';

abstract class WalletDetailEvent {}

class WalletDetailBalanceEvent extends WalletDetailEvent {
  CryptoType type;
  WalletStorage wallet;

  WalletDetailBalanceEvent(this.type, this.wallet);
}

class WalletDetailState {
  String address = "";
  String balance = "";
  String balanceInUSD = "";

  WalletDetailState({
    this.address = "",
    this.balance = "",
    this.balanceInUSD = "",
  });

  WalletDetailState copyWith({
    String? address,
    String? balance,
    String? balanceInUSD,
  }) {
    return WalletDetailState(
      address: address ?? this.address,
      balance: balance ?? this.balance,
      balanceInUSD: balanceInUSD ?? this.balanceInUSD,
    );
  }
}
