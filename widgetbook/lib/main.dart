import 'package:autonomy_flutter/widgetbook/components/ff_cast_button.dart';
import 'package:autonomy_flutter/widgetbook/components/header_view.dart';
import 'package:autonomy_flutter/widgetbook/components/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

void main() {
  runApp(const WidgetbookApp());
}

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      lightTheme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: Container(
        color: Colors.white,
        child: const Center(
          child: Text('Widgetbook Home Screen'),
        ),
      ),
      addons: [
        //DeviceFrameAddon should be used before all other addons.
        DeviceFrameAddon(
          devices: [
            ...Devices.all,
          ],
          initialDevice: Devices.android.pixel4,
        ),
        // ViewportAddon(Viewports.all),
        InspectorAddon(
          enabled: true,
        ),
        GridAddon(10),
        AlignmentAddon(),
        TextScaleAddon(),
        MaterialThemeAddon(themes: [
          WidgetbookTheme(
            name: 'Light Theme',
            data: ThemeData.light(),
          ),
          WidgetbookTheme(
            name: 'Dark Theme',
            data: ThemeData.dark(),
          ),
        ]),
      ],
      directories: [
        WidgetbookFolder(
          name: 'Components',
          children: [
            headerViewComponent,
            loadingWidgetComponent,
            ffCastButtonComponent,
          ],
        ),
      ],
    );
  }
}
