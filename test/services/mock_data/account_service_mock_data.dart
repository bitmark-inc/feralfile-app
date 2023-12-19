// ignore_for_file: discarded_futures

import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:mockito/mockito.dart';

class AccountServiceMockData {
  static void setup(AccountService mockAccountService) {
    when(mockAccountService.getAccountByAddress(
            chain: anyNamed('chain'), address: anyNamed('address')))
        .thenAnswer((_) async => WalletIndex(WalletStorage('uuid'), 0));
  }
}
