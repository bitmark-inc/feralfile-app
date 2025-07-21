// widgetbook for accountItem
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/model/wallet_address.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_state.dart';
import 'package:autonomy_flutter/view/account_view.dart';
import 'package:autonomy_flutter/widgetbook/mock/mock_address_service.dart';
import 'package:autonomy_flutter/widgetbook/mock/mock_cloud_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:widgetbook/widgetbook.dart';

final accountItemComponent = WidgetbookComponent(
  name: 'AccountItem',
  useCases: [
    WidgetbookUseCase(
      name: 'default',
      builder: (context) => useCaseAccountItem(context),
    ),
  ],
);

Widget useCaseAccountItem(BuildContext context) {
  final name = context.knobs.string(
    label: 'Name',
    initialValue: 'Test Account',
  );

  final isHidden = context.knobs.boolean(
    label: 'Is Hidden',
    initialValue: true,
  );

  final address = WalletAddress(
    name: name,
    address: '0x1234567890abcdef1234567890abcdef12345678', // Ethereum address
    createdAt: DateTime.now(),
    isHidden: isHidden,
  );

  // Mock AccountsBloc với state mặc định
  final mockAccountsBloc = AccountsBloc(
    MockAddressService(),
    MockCloudManager(),
  );
  mockAccountsBloc.emit(AccountsState(
    addressBalances: {
      address.address:
          Pair(BigInt.from(1000000000000000000), '1 NFT'), // 1 ETH và 1 NFT
    },
  ));

  return BlocProvider<AccountsBloc>.value(
    value: mockAccountsBloc,
    child: Center(
      child: accountItem(
        context,
        address,
      ),
    ),
  );
}
