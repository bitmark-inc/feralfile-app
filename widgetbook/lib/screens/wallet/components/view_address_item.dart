import 'package:autonomy_flutter/view/view_address_item.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/mock/mock_wallet_data.dart';

class ViewAddressItemComponent extends WidgetbookComponent {
  ViewAddressItemComponent()
      : super(
          name: 'ViewAddressItem',
          useCases: [
            WidgetbookUseCase(
              name: 'Default',
              builder: (context) => const ViewAddressItem(
                address: '0x1234...5678',
                name: 'Ethereum',
                cryptoType: 'ETH',
              ),
            ),
            WidgetbookUseCase(
              name: 'With OnTap',
              builder: (context) => ViewAddressItem(
                address: '0x1234...5678',
                name: 'Ethereum',
                cryptoType: 'ETH',
                onTap: () {},
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
                  return ViewAddressItem(
                    address: address.address,
                    name: address.name,
                    cryptoType: address.cryptoType.name,
                    onTap: () {},
                  );
                },
              ),
            ),
          ],
        );
}
