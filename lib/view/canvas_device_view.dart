import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_tv_proto/models/canvas_device.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CanvasDeviceView extends StatefulWidget {
  final String sceneId;
  final Function? onClose;

  const CanvasDeviceView({Key? key, required this.sceneId, this.onClose})
      : super(key: key);

  @override
  State<CanvasDeviceView> createState() => _CanvasDeviceViewState();
}

class _CanvasDeviceViewState extends State<CanvasDeviceView> {
  late final CanvasDeviceBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<CanvasDeviceBloc>();
    _fetchDevice();
  }

  Future<void> _fetchDevice() async {
    _bloc.add(CanvasDeviceGetDevicesEvent(widget.sceneId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<CanvasDeviceBloc, CanvasDeviceState>(
      listener: (context, state) {
        setState(() {});
        if (state.isConnectError) {
          UIHelper.showInfoDialog(
              context, "fail_to_connect".tr(), "canvas_fail_des".tr(),
              closeButton: "close".tr());
        }
      },
      builder: (context, state) {
        final devices = state.devices;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("connect_to_frame".tr(),
                      style: theme.textTheme.ppMori700White24),
                  const SizedBox(height: 40),
                  RichText(
                      text: TextSpan(children: <TextSpan>[
                    TextSpan(
                      text: "display_your_artwork_on".tr(),
                      style: theme.textTheme.ppMori400White14,
                    ),
                    TextSpan(
                      text: "compatible_platforms".tr(),
                      style: theme.textTheme.ppMori400Green14,
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Navigator.of(context)
                            .pushNamed(AppRouter.canvasHelpPage),
                    ),
                    TextSpan(
                      text: "for_a_better_viewing".tr(),
                      style: theme.textTheme.ppMori400White14,
                    ),
                  ])),
                ],
              ),
            ),
            const SizedBox(height: 40),
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
            const SizedBox(height: 40),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _newCanvas(state),
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

  Widget _newCanvas(CanvasDeviceState state) {
    final theme = Theme.of(context);
    if (!state.isLoaded) {
      return const SizedBox();
    } else if (state.devices.isEmpty) {
      return Column(
        children: [
          PrimaryButton(
            text: "add_new_frame".tr(),
            onTap: () => _addNewCanvas(),
          ),
          const SizedBox(height: 10),
        ],
      );
    } else {
      return Column(
        children: [
          GestureDetector(
            onTap: () => _addNewCanvas(),
            child: Container(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Row(
                children: [
                  Text(
                    "add_new_frame".tr(),
                    style: theme.textTheme.ppMori400Green14,
                  ),
                  const Spacer(),
                  SvgPicture.asset("assets/images/joinFile.svg",
                      color: AppColor.auSuperTeal),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      );
    }
  }

  Future<void> _addNewCanvas() async {
    dynamic device = await Navigator.of(context)
        .pushNamed(ScanQRPage.tag, arguments: ScannerItem.CANVAS_DEVICE);
    if (!mounted) return;
    if (device != null && device is CanvasDevice) {
      _bloc.add(CanvasDeviceAddEvent(DeviceState(device: device)));
    }
  }

  // row view show DeviceState display name and status
  Widget _deviceRow(DeviceState deviceState) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: ResponsiveLayout.pageHorizontalEdgeInsets
              .copyWith(top: 20, bottom: 20),
          child: Container(
            decoration: const BoxDecoration(color: Colors.transparent),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    deviceState.device.name,
                    style: (deviceState.status == DeviceStatus.error)
                        ? theme.textTheme.ppMori700Black14
                            .copyWith(color: AppColor.disabledColor)
                        : theme.textTheme.ppMori700White14,
                  ),
                ),
                const Spacer(),
                const SizedBox(
                  width: 20,
                ),
                IconButton(
                  onPressed: () {
                    _bloc.add(CanvasDeviceRotateEvent(deviceState.device));
                  },
                  icon: const Icon(AuIcon.rotateRounded, color: AppColor.white),
                ),
                _deviceStatus(deviceState),
              ],
            ),
          ),
        ),
        addOnlyDivider(),
      ],
    );
  }

  Widget _deviceStatus(DeviceState deviceState) {
    final theme = Theme.of(context);
    switch (deviceState.status) {
      case DeviceStatus.loading:
        return GestureDetector(
          onTap: () {
            _bloc.add(CanvasDeviceUncastingSingleEvent(deviceState.device));
          },
          child: loadingIndicator(
              size: 22,
              valueColor: AppColor.white,
              backgroundColor: AppColor.greyMedium),
        );
      case DeviceStatus.playing:
        return Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: AppColor.auSuperTeal),
                borderRadius: BorderRadius.circular(15.0),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              child:
                  Text("playing".tr(), style: theme.textTheme.ppMori400Green12),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              child: SvgPicture.asset(
                "assets/images/stop_icon.svg",
                width: 30,
                height: 30,
              ),
              onTap: () {
                _bloc.add(CanvasDeviceUncastingSingleEvent(deviceState.device));
              },
            ),
          ],
        );
      case DeviceStatus.connected:
        return GestureDetector(
          child: SvgPicture.asset(
            "assets/images/play_canvas_icon.svg",
            color: AppColor.white,
          ),
          onTap: () {
            _bloc.add(CanvasDeviceCastSingleEvent(
                deviceState.device, widget.sceneId));
          },
        );
      case DeviceStatus.error:
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(AppRouter.canvasHelpPage);
          },
          child: SvgPicture.asset(
            "assets/images/help_icon.svg",
            color: AppColor.auSuperTeal,
          ),
        );
    }
  }
}
