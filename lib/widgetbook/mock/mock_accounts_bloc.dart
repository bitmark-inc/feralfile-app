import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_state.dart';

import 'mock_address_service.dart';
import 'mock_cloud_manager.dart';
import 'mock_wallet_data.dart';

class MockAccountsBloc extends AccountsBloc {
  MockAccountsBloc() : super(MockAddressService(), MockCloudManager()) {
    final addresses = MockWalletData.getAddresses();
    emit(AccountsState(
      addresses: addresses,
      addressBalances: {
        addresses.first.address: '1 NFT',
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
          addresses.first.address: '1 NFT',
        },
      ));
    }
  }
}
