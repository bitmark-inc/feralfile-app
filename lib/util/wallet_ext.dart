import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:flutter/foundation.dart';
import 'package:libauk_dart/libauk_dart.dart';

extension WalletExt on Pair<WalletStorage, int> {
  Future<Map<String, dynamic>> get chatAuthBody async {
    final address = await first.getTezosAddress(index: second);
    final pubKey = await first.getTezosPublicKey(index: second);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final authSig = await injector<TezosService>().signMessage(
        first, second, Uint8List.fromList(utf8.encode(timestamp.toString())));
    return {
      'address': address,
      'public_key': pubKey,
      'signature': authSig,
      'timestamp': timestamp,
    };
  }
}
