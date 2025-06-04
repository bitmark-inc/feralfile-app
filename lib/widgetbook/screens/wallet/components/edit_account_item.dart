import 'package:autonomy_flutter/view/edit_account_item.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:autonomy_flutter/widgetbook/mock/mock_wallet_data.dart';

class EditAccountItemComponent extends WidgetbookComponent {
  EditAccountItemComponent()
      : super(
          name: 'EditAccountItem',
          useCases: [
            WidgetbookUseCase(
              name: 'Default',
              builder: (context) => const EditAccountItem(
                address: '0x1234...5678',
                name: 'Ethereum',
                cryptoType: 'ETH',
              ),
            ),
            WidgetbookUseCase(
              name: 'With Actions',
              builder: (context) => EditAccountItem(
                address: '0x1234...5678',
                name: 'Ethereum',
                cryptoType: 'ETH',
                onTap: () {},
                onEdit: () {},
                onDelete: () {},
              ),
            ),
            WidgetbookUseCase(
              name: 'With Mock Data',
              builder: (context) => FutureBuilder(
                future: Future.delayed(
                  const Duration(seconds: 1),
                  () => MockWalletData.getAddresses().first,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final address = snapshot.data!;
                  return EditAccountItem(
                    address: address.address,
                    name: address.name,
                    cryptoType: address.cryptoType.name,
                    onTap: () {},
                    onEdit: () {},
                    onDelete: () {},
                  );
                },
              ),
            ),
          ],
        );
}
