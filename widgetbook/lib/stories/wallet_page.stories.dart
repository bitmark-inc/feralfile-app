import 'package:autonomy_flutter/screen/wallet/wallet_page.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/components/mock_wrapper.dart';

class WalletPageComponent extends WidgetbookComponent {
  WalletPageComponent()
      : super(
          name: 'Wallet Page',
          useCases: [
            WidgetbookUseCase(
              name: 'Default',
              builder: (context) => const MockWrapper(
                child: WalletPage(
                  payload: WalletPagePayload(openAddAddress: false),
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'With Add Address',
              builder: (context) => const MockWrapper(
                child: WalletPage(
                  payload: WalletPagePayload(openAddAddress: true),
                ),
              ),
            ),
          ],
        );
}
