import 'package:autonomy_flutter/view/no_edit_addresses_list.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/mock/mock_wallet_data.dart';

class NoEditAddressesListComponent extends WidgetbookComponent {
  NoEditAddressesListComponent()
      : super(
          name: 'NoEditAddressesList',
          useCases: [
            WidgetbookUseCase(
              name: 'Default',
              builder: (context) => const NoEditAddressesList(),
            ),
            WidgetbookUseCase(
              name: 'With Mock Data',
              builder: (context) => FutureBuilder(
                future: Future.delayed(
                  const Duration(seconds: 1),
                  () => MockWalletData.getNoEditAddresses(),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return const NoEditAddressesList();
                },
              ),
            ),
          ],
        );
}
