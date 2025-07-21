import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/model/wallet_address.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_state.dart';
import 'mock_wallet_data.dart';
import 'mock_address_service.dart';
import 'mock_cloud_manager.dart';

class MockAccountsBloc extends AccountsBloc {
  MockAccountsBloc() : super(MockAddressService(), MockCloudManager()) {
    final addresses = MockWalletData.getAddresses();
    emit(AccountsState(
      addresses: addresses,
      addressBalances: {
        addresses.first.address:
            Pair(BigInt.from(1000000000000000000), '1 NFT'),
      },
    ));
  }

  @override
  void onEvent(AccountsEvent event) {
    if (event is GetAccountsEvent) {
      final addresses = MockWalletData.getAddresses();
      emit(AccountsState(
        addresses: addresses,
        addressBalances: {
          addresses.first.address:
              Pair(BigInt.from(1000000000000000000), '1 NFT'),
        },
      ));
    }
  }
}
