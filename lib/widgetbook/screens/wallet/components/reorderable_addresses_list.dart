import 'package:autonomy_flutter/screen/settings/connection/accounts_view.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

class ReorderableAddressesListComponent extends WidgetbookComponent {
  ReorderableAddressesListComponent()
      : super(
          name: 'Reorderable Addresses List',
          useCases: [
            WidgetbookUseCase(
              name: 'Default',
              builder: (context) => ReorderableListView(
                children: List.generate(
                  3,
                  (index) => ListTile(
                    key: ValueKey('item_$index'),
                    title: Text('Address ${index + 1}'),
                    subtitle: Text('0x1234...5678'),
                    trailing: const Icon(Icons.drag_handle),
                  ),
                ),
                onReorder: (oldIndex, newIndex) {},
              ),
            ),
          ],
        );
}
