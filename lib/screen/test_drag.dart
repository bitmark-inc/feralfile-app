import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/canvas_client_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_tv_proto/autonomy_tv_proto.dart';
import 'package:flutter/material.dart';

class TestDrag extends StatefulWidget {
  final CanvasDevice device;

  const TestDrag({super.key, required this.device});

  @override
  State<TestDrag> createState() => _TestDragState();
}

class _TestDragState extends State<TestDrag> {
  final width = 400.0;
  final height = 700.0;
  final _canvasClient = injector<CanvasClientService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getCloseAppBar(context, onClose: () {
        Navigator.of(context).pop();
      }),
      body: Column(
        children: [
          Container(
            color: Colors.amber,
            height: height,
            width: width,
            child: GestureDetector(
              onTap: () {
                log.info("onTap");
                _canvasClient.tap(widget.device);
              },
              onPanUpdate: (panDetails) {
                log.info(panDetails.delta);
                _canvasClient.drag(widget.device, panDetails.delta);
              },
              onPanStart: (dragStartDetails) {
                log.info("onPanStart");
              },
              onPanEnd: (dragEndDetails) {
                log.info("onPanEnd");
              },
              onPanDown: (dragDownDetails) {
                log.info("onPanDown ");
              },
              onPanCancel: () {
                log.info("onPanCancel");
              },
            ),
          )
        ],
      ),
    );
  }
}
