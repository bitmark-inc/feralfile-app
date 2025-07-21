import 'package:autonomy_flutter/screen/settings/connection/accounts_view.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

class AccountsViewComponent extends WidgetbookComponent {
  AccountsViewComponent()
      : super(
          name: 'Accounts View',
          useCases: [
            WidgetbookUseCase(
              name: 'Default',
              builder: (context) => const AccountsView(
                isInSettingsPage: true,
              ),
            ),
            WidgetbookUseCase(
              name: 'With Scroll Controller',
              builder: (context) => AccountsView(
                isInSettingsPage: true,
                scrollController: ScrollController(),
              ),
            ),
          ],
        );
}
