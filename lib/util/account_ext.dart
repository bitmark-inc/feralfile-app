import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:collection/collection.dart';

extension AccountExt on Account {
  Future<String?> getAddress(String blockchain) async {
    final wallet = persona?.wallet();
    String? address;
    if (wallet != null) {
      address = blockchain.toLowerCase() == "tezos"
          ? await wallet.getTezosAddress()
          : await wallet.getETHEip55Address();
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
