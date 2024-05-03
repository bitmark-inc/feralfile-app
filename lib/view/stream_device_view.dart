import 'dart:async';

import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/stream_common_widget.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StreamDeviceView extends StatefulWidget {
  final Function(String device)? onDeviceSelected;
  const StreamDeviceView({
    super.key,
    this.onDeviceSelected,
  });

  @override
  State<StreamDeviceView> createState() => _StreamDeviceViewState();
}

class _StreamDeviceViewState extends State<StreamDeviceView> {
  late final CanvasDeviceBloc _canvasDeviceBloc;

  @override
  void initState() {
    super.initState();
    _canvasDeviceBloc = context.read<CanvasDeviceBloc>();
    unawaited(_fetchDevice());
  }

  Future<void> _fetchDevice() async {
    _canvasDeviceBloc.add(CanvasDeviceGetDevicesEvent(''));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<CanvasDeviceBloc, CanvasDeviceState>(
      builder: (context, state) {
        final devices = state.devices;
        final connectedDevice = devices
            .firstWhereOrNull((deviceState) => deviceState.device.isConnecting)
            ?.device;
        const isPlaylist = true;
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
              if (isPlaylist) ...[
                const PlaylistControl(),
                const SizedBox(height: 40),
              ],
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: devices.length,
                itemBuilder: (BuildContext context, int index) {
                  final device = devices[index].device;
                  final isConnected = device.id == connectedDevice?.id;
                  return Column(
                    children: [
                      Builder(
                        builder: (context) => StreamDrawerItem(
                          item: OptionItem(
                              title: device.name,
                              onTap: () {
                                log.info('device selected: ${device.id}');
                                widget.onDeviceSelected?.call(device.id);
                              }),
                          backgroundColor: connectedDevice == null
                              ? AppColor.white
                              : isConnected
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
              if (connectedDevice != null) ...[
                const SizedBox(
                  height: 40,
                ),
                GestureDetector(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: AppColor.white,
                      ),
                    ),
                    width: MediaQuery.of(context).size.width,
                    child: Center(
                      child: Text(
                        'disconnect'.tr(),
                        style: theme.textTheme.ppMori400White14,
                      ),
                    ),
                  ),
                  onTap: () => {},
                )
              ]
            ],
          ),
        );
      },
    );
  }
}
