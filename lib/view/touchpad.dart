import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/canvas_client_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_tv_proto/models/canvas_device.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class TouchPad extends StatefulWidget {
  final CanvasDevice device;
  final Function()? onExpand;

  const TouchPad({super.key, required this.device, this.onExpand});

  @override
  State<TouchPad> createState() => _TouchPadState();
}

class _TouchPadState extends State<TouchPad> {
  final _canvasClient = injector<CanvasClientService>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), color: Colors.black),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              log.info("[Touchpad] onTap");
              _canvasClient.tap(widget.device);
            },
            onPanUpdate: (panDetails) {
              _canvasClient.drag(widget.device, panDetails.delta);
            },
          ),
          Positioned(
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Text(
                "touchpad".tr(),
                style: theme.textTheme.ppMori400White14
                    .copyWith(color: AppColor.auGreyBackground),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
              child: GestureDetector(
                child: SvgPicture.asset("assets/images/Expand.svg"),
                onTap: () {
                  widget.onExpand?.call();
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
