import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_page.dart';

abstract class WalletDetailEvent {}

class WalletDetailBalanceEvent extends WalletDetailEvent {
  CryptoType type;

  WalletDetailBalanceEvent(this.type);
}

class WalletDetailState {
  String address = "";
  String balance = "";
  String balanceInUSD = "";
}
