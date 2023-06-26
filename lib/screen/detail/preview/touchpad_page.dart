import 'package:autonomy_flutter/view/touchpad.dart';
import 'package:autonomy_theme/style/colors.dart';
import 'package:autonomy_tv_proto/autonomy_tv_proto.dart';
import 'package:flutter/material.dart';

class TouchPadPagePayload {
  final List<CanvasDevice> devices;

  TouchPadPagePayload(this.devices);
}

class TouchPadPage extends StatefulWidget {
  final TouchPadPagePayload payload;

  const TouchPadPage({super.key, required this.payload});

  @override
  State<TouchPadPage> createState() => _TouchPadPageState();
}

class _TouchPadPageState extends State<TouchPadPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      appBar: AppBar(
        toolbarHeight: 0.0,
      ),
      body: Container(
        color: AppColor.disabledColor,
        padding: const EdgeInsets.all(15),
        child: RotatedBox(
          quarterTurns: -1,
          child: Column(
            children: [
              Expanded(
                child: TouchPad(
                  devices: widget.payload.devices,
                  onExpand: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
