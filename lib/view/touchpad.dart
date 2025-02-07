import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class TouchPad extends StatefulWidget {
  final List<BaseDevice> devices;
  final Function()? onExpand;

  const TouchPad({required this.devices, super.key, this.onExpand});

  @override
  State<TouchPad> createState() => _TouchPadState();
}

class _TouchPadState extends State<TouchPad> with AfterLayoutMixin {
  final _canvasClient = injector<CanvasClientServiceV2>();
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
    return DecoratedBox(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), color: Colors.black),
      child: Stack(
        children: [
          GestureDetector(
            key: _touchPadKey,
            onTap: () async {
              log.info('[Touchpad] onTap');
              await _canvasClient.tap(widget.devices);
            },
            onPanStart: (panDetails) {
              _getSize();
            },
            onPanUpdate: (panDetails) {
              Offset delta = panDetails.delta;
              unawaited(
                  _canvasClient.drag(widget.devices, delta, _touchpadSize!));
            },
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Text(
                'touchpad'.tr(),
                style: theme.textTheme.ppMori400White14
                    .copyWith(color: AppColor.auGrey),
              ),
            ),
          ),
          if (widget.onExpand != null)
            Positioned(
              bottom: 0,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: GestureDetector(
                  child: SvgPicture.asset('assets/images/Expand.svg'),
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
