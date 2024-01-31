import 'package:autonomy_flutter/view/touchpad.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:flutter/material.dart';

class TouchPadPagePayload {
  final List<CanvasDevice> devices;

  TouchPadPagePayload(this.devices);
}

class TouchPadPage extends StatefulWidget {
  final TouchPadPagePayload payload;

  const TouchPadPage({required this.payload, super.key});

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
        toolbarHeight: 0,
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
