// lib/widgetbook_screen.dart
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/components/ff_cast_button.dart';
import 'package:widgetbook_workspace/components/header_view.dart';
import 'package:widgetbook_workspace/main.directories.g.dart';

class WidgetbookScreen extends StatelessWidget {
  const WidgetbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [
        ...directories,
        WidgetbookFolder(
          name: 'Components',
          children: [
            headerViewComponent,
            // loadingWidgetComponent,
            ffCastButtonComponent,
          ],
        ),
      ],
    );
  }
}
