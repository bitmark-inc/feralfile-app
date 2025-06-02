import 'package:autonomy_flutter/screen/wallet/wallet_page.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/components/mock_wrapper.dart';

final WidgetbookComponent walletPageComponent = WidgetbookComponent(
  name: 'WalletPage',
  useCases: [
    WidgetbookUseCase(
      name: 'Default',
      builder: (context) => const MockWrapper(
        child: WalletPage(),
      ),
    ),
  ],
);
