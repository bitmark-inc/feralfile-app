import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/view/badge_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PenroseTopBarView extends StatefulWidget {
  final bool pushToSettings;
  final ScrollController scrollController;

  PenroseTopBarView(this.pushToSettings, this.scrollController);

  @override
  State<PenroseTopBarView> createState() => _PenroseTopBarViewState();
}

class _PenroseTopBarViewState extends State<PenroseTopBarView> {
  double _opacity = 1;

  @override
  void initState() {
    super.initState();

    widget.scrollController.addListener(_scrollListener);
  }

  _scrollListener() {
    if (widget.scrollController.offset > 80) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      setState(() {
        _opacity = 0;
      });
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
      setState(() {
        _opacity = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      builder: (context, value) => Stack(fit: StackFit.loose, children: [
        Opacity(
          opacity: _opacity,
          child: Container(
            alignment: Alignment.topCenter,
            padding: EdgeInsets.fromLTRB(7, 42, 12, 90),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(0, 0, 12, 12),
                  child: IconButton(
                    constraints: BoxConstraints(),
                    icon: SvgPicture.asset("assets/images/iconQr.svg"),
                    onPressed: () {
                      if (_opacity == 0) return;
                      Navigator.of(context).pushNamed(AppRouter.scanQRPage,
                          arguments: ScannerItem.GLOBAL);
                    },
                  ),
                ),
                Spacer(),
                _customerSupportIconWidget(),
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
                child: _logo(),
                onTap: () => widget.pushToSettings
                    ? Navigator.of(context).pushNamed(AppRouter.settingsPage)
                    : Navigator.of(context).pop()),
          ),
        ),
      ]),
      animation: widget.scrollController,
    );
  }

  Widget _logo() {
    return FutureBuilder<bool>(
        future: isAppCenterBuild(),
        builder: (context, snapshot) {
          return SvgPicture.asset(snapshot.data == true
              ? "assets/images/penrose_appcenter.svg"
              : "assets/images/penrose.svg");
        });
  }

  Widget _customerSupportIconWidget() {
    return ValueListenableBuilder<List<int>?>(
        valueListenable: injector<CustomerSupportService>().numberOfIssuesInfo,
        builder: (BuildContext context, List<int>? numberOfIssuesInfo,
            Widget? child) {
          final unreadIssues = numberOfIssuesInfo?[1] ?? 0;
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 10, 0, 20),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SvgPicture.asset("assets/images/iconCustomerSupport.svg"),
                  if (unreadIssues == 0) ...[
                    Positioned(
                        top: -5,
                        left: 15,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: BadgeView(number: unreadIssues),
                        )),
                  ]
                ],
              ),
            ),
            onTap: () {
              if (_opacity == 0) return;
              Navigator.of(context).pushNamed(AppRouter.supportCustomerPage);
            },
          );
        });
  }
}
