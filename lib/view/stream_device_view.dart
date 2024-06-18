import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/stream_common_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:feralfile_app_tv_proto/models/canvas_device.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            : state.castingDeviceForKey(widget.displayKey!);
        return Padding(
          padding: ResponsiveLayout.pageHorizontalEdgeInsets,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
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
                                log.info('device selected: ${device.deviceId}');
                                widget.onDeviceSelected?.call(device);
                              }),
                          backgroundColor: connectedDevice == null
                              ? AppColor.white
                              : isControlling
                                  ? AppColor.feralFileLightBlue
                                  : AppColor.disabledColor,
                        ),
                      ),
                      if (index < devices.length - 1)
                        const SizedBox(
                          height: 15,
                        )
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              RichText(
                  text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: 'not_find_canvas'.tr(),
                    style: theme.textTheme.ppMori400White14,
                  ),
                  // text clickable
                  TextSpan(
                    text: 'scan_the_qrcode'.tr(),
                    style: theme.textTheme.ppMori400White14.copyWith(
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        await _scanToAddMore(context);
                      },
                  ),
                  TextSpan(
                    text: 'that_appear_on_canvas'.tr(),
                    style: theme.textTheme.ppMori400White14,
                  )
                ],
              )),
              if (connectedDevice != null) ...[
                const SizedBox(
                  height: 40,
                ),
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
              ]
            ],
          ),
        );
      },
    );
  }

  Future<void> _scanToAddMore(BuildContext context) async {
    final device = await Navigator.of(context)
        .pushNamed(AppRouter.scanQRPage, arguments: ScannerItem.CANVAS);
    log.info('device selected: $device');
    _canvasDeviceBloc.add(CanvasDeviceGetDevicesEvent());
  }

  Future<void> onDisconnect() async {
    final allDevices =
        _canvasDeviceBloc.state.devices.map((e) => e.device).toList();
    _canvasDeviceBloc.add(CanvasDeviceDisconnectEvent(allDevices));
  }
}
