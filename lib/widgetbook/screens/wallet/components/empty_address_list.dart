import 'package:autonomy_flutter/view/empty_address_list.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:autonomy_flutter/widgetbook/mock/mock_wallet_data.dart';

class EmptyAddressListComponent extends WidgetbookComponent {
  EmptyAddressListComponent()
      : super(
          name: 'EmptyAddressList',
          useCases: [
            WidgetbookUseCase(
              name: 'Default',
              builder: (context) => const EmptyAddressList(),
            ),
            WidgetbookUseCase(
              name: 'With Mock Data',
              builder: (context) => FutureBuilder(
                future: Future.delayed(
                  const Duration(seconds: 1),
                  () => MockWalletData.getEmptyAddresses(),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return const EmptyAddressList();
                },
              ),
            ),
          ],
        );
}
