import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/canvas_client_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_tv_proto/models/canvas_device.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class TouchPad extends StatefulWidget {
  final List<CanvasDevice> devices;
  final Function()? onExpand;

  const TouchPad({super.key, required this.devices, this.onExpand});

  @override
  State<TouchPad> createState() => _TouchPadState();
}

class _TouchPadState extends State<TouchPad> with AfterLayoutMixin {
  final _canvasClient = injector<CanvasClientService>();
  final _touchPadKey = GlobalKey();
  Size? _touchpadSize;

  Size? _getSize() {
    final size = MediaQuery.of(context).size;
    setState(() {
      _touchpadSize = size;
    });
    return size;
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _getSize();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), color: Colors.black),
      child: Stack(
        children: [
          GestureDetector(
            key: _touchPadKey,
            onTap: () {
              log.info("[Touchpad] onTap");
              _canvasClient.tap(widget.devices);
            },
            onPanStart: (panDetails) {
              _getSize();
            },
            onPanUpdate: (panDetails) {
              Offset delta = panDetails.delta;
              _canvasClient.drag(widget.devices, delta, _touchpadSize!);
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
