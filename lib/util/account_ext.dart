import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:collection/collection.dart';

extension AccountExt on Account {
  Future<String?> getAddress(String blockchain) async {
    final wallet = persona?.wallet();
    String? address;
    if (wallet != null) {
      address = blockchain.toLowerCase() == "tezos"
          ? (await wallet.getTezosWallet()).address
          : await wallet.getETHAddress();
    } else if (connections?.isNotEmpty == true) {
      final connectionType = blockchain.toLowerCase() == "tezos"
          ? "walletBeacon"
          : "walletConnect";
      address = connections
          ?.firstWhereOrNull((e) => e.connectionType == connectionType)
          ?.accountNumber;
    }
    return address;
  }
}
