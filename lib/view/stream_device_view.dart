import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/display_instruction_view.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/stream_common_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:feralfile_app_tv_proto/models/canvas_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StreamDeviceView extends StatefulWidget {
  final Function(CanvasDevice device)? onDeviceSelected;
  final String? displayKey;

  const StreamDeviceView({
    super.key,
    this.onDeviceSelected,
    this.displayKey,
  });

  @override
  State<StreamDeviceView> createState() => _StreamDeviceViewState();
}

class _StreamDeviceViewState extends State<StreamDeviceView> {
  late final CanvasDeviceBloc _canvasDeviceBloc;

  @override
  void initState() {
    super.initState();
    _canvasDeviceBloc = injector.get<CanvasDeviceBloc>();
    unawaited(_fetchDevice());
  }

  Future<void> _fetchDevice() async {
    _canvasDeviceBloc.add(CanvasDeviceGetDevicesEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<CanvasDeviceBloc, CanvasDeviceState>(
      bloc: _canvasDeviceBloc,
      builder: (context, state) {
        final devices = state.devices;
        final connectedDevice = widget.displayKey == null
            ? null
            : state.lastSelectedActiveDeviceForKey(widget.displayKey!);
        return Padding(
          padding: ResponsiveLayout.pageHorizontalEdgeInsets,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            text: 'display'.tr(),
                            style: theme.textTheme.ppMori700White24,
                          ),
                          if (connectedDevice != null)
                            TextSpan(
                              text: ' ${connectedDevice.name}',
                              style: theme.textTheme.ppMori400White24,
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SvgPicture.asset(
                        'assets/images/circle_close.svg',
                        width: 22,
                        height: 22,
                      ),
                    ),
                  )
                ],
              ),
              if (devices.isNotEmpty) ...[
                const SizedBox(height: 40),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: devices.length,
                  itemBuilder: (BuildContext context, int index) {
                    final device = devices[index].device;
                    final isControlling =
                        device.deviceId == connectedDevice?.deviceId;
                    return Column(
                      children: [
                        Builder(
                          builder: (context) => StreamDrawerItem(
                            item: OptionItem(
                                title: device.name,
                                onTap: () {
                                  log.info(
                                      'device selected: ${device.deviceId}');
                                  widget.onDeviceSelected?.call(device);
                                }),
                            backgroundColor: connectedDevice == null
                                ? AppColor.white
                                : isControlling
                                    ? AppColor.feralFileLightBlue
                                    : AppColor.disabledColor,
                            isControlling: isControlling,
                            onRotateClicked: () => onRotate(context),
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        )
                      ],
                    );
                  },
                ),
                if (connectedDevice != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: AppColor.white,
                      ),
                    ),
                    width: MediaQuery.of(context).size.width,
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        splashFactory: InkSparkle.splashFactory,
                        borderRadius: BorderRadius.circular(50),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Center(
                            child: Text(
                              'disconnect'.tr(),
                              style: theme.textTheme.ppMori400White14,
                            ),
                          ),
                        ),
                        onTap: () async {
                          await onDisconnect();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
                _instructionView(context),
              ] else
                _instructionDetailWidget(context),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _instructionDetailWidget(BuildContext context) =>
      DisplayInstructionView(
        onScanQRTap: () async {
          await _scanToAddMore(context);
        },
      );

  Widget _instructionView(BuildContext context) => SectionExpandedWidget(
        header: 'instructions'.tr(),
        child: _instructionDetailWidget(context),
      );

  void onRotate(BuildContext context) {
    final lastSelectedCanvasDevice = _canvasDeviceBloc.state
        .lastSelectedActiveDeviceForKey(widget.displayKey!);
    if (lastSelectedCanvasDevice != null) {
      _canvasDeviceBloc.add(CanvasDeviceRotateEvent(lastSelectedCanvasDevice));
    }
  }

  Future<void> _scanToAddMore(BuildContext context) async {
    final device = await Navigator.of(context)
        .pushNamed(AppRouter.scanQRPage, arguments: ScannerItem.CANVAS);
    log.info('device selected: $device');
    if (device != null) {
      _canvasDeviceBloc.add(CanvasDeviceGetDevicesEvent());
    }
  }

  Future<void> onDisconnect() async {
    final allDevices =
        _canvasDeviceBloc.state.devices.map((e) => e.device).toList();
    _canvasDeviceBloc.add(CanvasDeviceDisconnectEvent(allDevices));
  }
}
