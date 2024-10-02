import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:collection/collection.dart';
import 'package:libauk_dart/libauk_dart.dart';

extension AccountExt on Account {
  Future<String?> getAddress(String blockchain) async {
    String? address;
    if (wallet != null) {
      address = blockchain.toLowerCase() == 'tezos'
          ? await wallet!.getTezosAddress()
          : await wallet!.getETHEip55Address();
    } else if (connections?.isNotEmpty == true) {
      final connectionType = blockchain.toLowerCase() == 'tezos'
          ? 'walletBeacon'
          : 'walletConnect';
      address = connections
          ?.firstWhereOrNull((e) => e.connectionType == connectionType)
          ?.accountNumber;
    }
    return address;
  }

  bool get isHidden => walletAddress != null
      ? walletAddress!.isHidden
      : injector<AccountService>().isLinkedAccountHiddenInGallery(key);

  Future<void> setViewAccount(bool value) async {
    if (walletAddress != null) {
      await injector<AccountService>()
          .setHideAddressInGallery([walletAddress!.address], value);
    } else {
      unawaited(
          injector<AccountService>().setHideLinkedAccountInGallery(key, value));
    }
  }

  CryptoType get cryptoType => CryptoType.fromSource(blockchain ?? '');

  WalletStorage? get wallet =>
      walletAddress != null ? LibAukDart.getWallet(walletAddress!.uuid) : null;
}
