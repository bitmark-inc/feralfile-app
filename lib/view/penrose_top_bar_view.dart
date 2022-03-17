import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PenroseTopBarView extends StatelessWidget {
  final bool pushToSettings;
  final ScrollController scrollController;

  PenroseTopBarView(this.pushToSettings, this.scrollController);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      builder: (context, value) => Stack(fit: StackFit.loose, children: [
        Opacity(
          opacity: scrollController.hasClients
              ? _opacityFromOffset(scrollController.offset)
              : 1,
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
                onTap: () => pushToSettings
                    ? Navigator.of(context).pushNamed(AppRouter.settingsPage)
                    : Navigator.of(context).pop()),
          ),
        ),
      ]),
      animation: scrollController,
    );
  }

  double _opacityFromOffset(double offset) {
    if (offset > 80) {
      return 0;
    } else if (offset <= 0) {
      return 1;
    } else {
      return (80 - scrollController.offset) / 100;
    }
  }
}
