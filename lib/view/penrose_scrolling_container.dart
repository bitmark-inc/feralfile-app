import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PenroseScrollingContainer extends StatefulWidget {
  final String page;
  final Widget? content;

  const PenroseScrollingContainer({Key? key, this.page = '', this.content})
      : super(key: key);

  @override
  State<PenroseScrollingContainer> createState() =>
      _PenroseScrollingContainerState();
}

class _PenroseScrollingContainerState extends State<PenroseScrollingContainer> {
  late ScrollController _controller;
  double _someElementsOpacity = 1;

  @override
  void initState() {
    _controller = ScrollController();
    _controller.addListener(_scrollListener);
    super.initState();
  }

  _scrollListener() {
    if (_controller.offset > 80) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
      setState(() {
        _someElementsOpacity = 0;
      });
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
      setState(() {
        _someElementsOpacity = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.loose, children: [
      Column(
        children: [
          Expanded(
              child: SingleChildScrollView(
                  controller: _controller,
                  child: Column(
                    children: [
                      SizedBox(height: 152),
                      widget.content ?? SizedBox()
                    ],
                  ))),
        ],
      ),
      Opacity(
        opacity: _someElementsOpacity,
        child: Container(
          alignment: Alignment.topCenter,
          padding: EdgeInsets.fromLTRB(7, 42, 12, 90),
          child: Row(
            children: [
              IconButton(
                constraints: BoxConstraints(),
                icon: SvgPicture.asset("assets/images/iconQr.svg"),
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.scanQRPage,
                      arguments: ScannerItem.GLOBAL);
                },
              ),
              Spacer(),
              GestureDetector(
                child: SvgPicture.asset("assets/images/iconReceive.svg"),
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRouter.globalReceivePage),
              ),
            ],
          ),
        ),
      ),
      Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding:
              EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12),
          child: GestureDetector(
            child: Image.asset("assets/images/penrose.png"),
            onTap: () {
              switch (widget.page) {
                case AppRouter.homePage:
                  Navigator.of(context).pushNamed(AppRouter.settingsPage);

                  break;
                case AppRouter.settingsPage:
                  Navigator.of(context).pop();
                  break;
                default:
                  break;
              }
            },
          ),
        ),
      ),
    ]);
  }
}
