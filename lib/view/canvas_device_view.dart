import 'package:autonomy_flutter/database/entity/canvas_device.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CanvasDeviceView extends StatefulWidget {
  final String sceneId;
  final Function? onClose;

  const CanvasDeviceView({Key? key, required this.sceneId, this.onClose})
      : super(key: key);

  @override
  State<CanvasDeviceView> createState() => _CanvasDeviceViewState();
}

class _CanvasDeviceViewState extends State<CanvasDeviceView> {
  @override
  void initState() {
    super.initState();
    context
        .read<CanvasDeviceBloc>()
        .add(CanvasDeviceGetDevicesEvent(widget.sceneId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<CanvasDeviceBloc, CanvasDeviceState>(
      listener: (context, state) {},
      builder: (context, state) {
        final devices = state.devices;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("connect_to_frame".tr(),
                style: theme.textTheme.ppMori700White24),
            const SizedBox(height: 40),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: RichText(
                  text: TextSpan(children: <TextSpan>[
                TextSpan(
                  text: "display_your_artwork_on".tr(),
                  style: theme.textTheme.ppMori400White14,
                ),
                TextSpan(
                  text: "compatible_platform".tr(),
                  style: theme.textTheme.ppMori400Green14,
                ),
                TextSpan(
                  text: "for_a_better_viewing".tr(),
                  style: theme.textTheme.ppMori400White14,
                ),
              ])),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: devices
                      .map((device) => [
                            _deviceRow(device),
                            addDivider(height: 1, color: AppColor.white),
                          ])
                      .flattened
                      .toList(),
                ),
              ),
            ),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      dynamic device = await Navigator.of(context).pushNamed(
                          ScanQRPage.tag,
                          arguments: ScannerItem.CANVAS_DEVICE);
                      if (!mounted) return;
                      if (device != null && device is CanvasDevice) {
                        context.read<CanvasDeviceBloc>().add(
                            CanvasDeviceAddEvent(DeviceState(device: device)));
                      }
                    },
                    child: Text(
                      "add_new_frame".tr(),
                      style: theme.textTheme.ppMori400Green14,
                    ),
                  ),
                  const SizedBox(height: 40),
                  OutlineButton(
                    text: "close".tr(),
                    onTap: () {
                      widget.onClose?.call();
                    },
                  ),
                ],
              ),
            )
          ],
        );
      },
    );
  }

  // row view show DeviceState display name and status
  Widget _deviceRow(DeviceState deviceState) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 100),
        Padding(
          padding: ResponsiveLayout.pageHorizontalEdgeInsets,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  deviceState.device.name,
                  style: theme.textTheme.ppMori400White14,
                ),
              ),
              Text(
                deviceState.status.toString(),
                style: theme.textTheme.ppMori400Green14,
              ),
            ],
          ),
        ),
        addOnlyDivider(),
      ],
    );
  }
}
