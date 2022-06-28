//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/badge_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum PenroseTopBarViewStyle {
  main,
  back,
}

class PenroseTopBarView extends StatefulWidget {
  final ScrollController scrollController;
  final PenroseTopBarViewStyle style;
  final Function()? onTapLogo;

  PenroseTopBarView(this.scrollController, this.style, this.onTapLogo);

  @override
  State<PenroseTopBarView> createState() => _PenroseTopBarViewState();
}

class _PenroseTopBarViewState extends State<PenroseTopBarView> with RouteAware {
  double _opacity = 1;

  @override
  void initState() {
    super.initState();

    widget.scrollController.addListener(_scrollListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    super.dispose();
    routeObserver.unsubscribe(this);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // Restore SystemUIMode
    _scrollListener();
  }

  void didPushNext() {
    // Reset to normal SystemUIMode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
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
        Opacity(opacity: _opacity, child: _headerWidget()),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: 62),
            child: GestureDetector(
              child: _logo(),
              onTap: widget.onTapLogo,
            ),
          ),
        ),
      ]),
      animation: widget.scrollController,
    );
  }

  Widget _headerWidget() {
    switch (widget.style) {
      case PenroseTopBarViewStyle.main:
        return Container(
          alignment: Alignment.topCenter,
          padding: EdgeInsets.fromLTRB(7, 42, 12, 90),
          child: _mainHeaderWidget(),
        );
      case PenroseTopBarViewStyle.back:
        return Container(
          alignment: Alignment.topCenter,
          padding: EdgeInsets.fromLTRB(16, 42, 12, 90),
          child: _backHeaderWidget(),
        );
    }
  }

  Widget _backHeaderWidget() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 7, 18, 8),
        child: Row(
          children: [
            Row(
              children: [
                SvgPicture.asset('assets/images/nav-arrow-left.svg'),
                SizedBox(width: 7),
                Text(
                  "BACK",
                  style: appTextTheme.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mainHeaderWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(0, 0, 10, 12),
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
        Container(
          padding: EdgeInsets.fromLTRB(0, 0, 12, 12),
          child: IconButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouter.feedPreviewPage),
              icon: SvgPicture.asset('assets/images/iconFeed.svg')),
        ),
        Spacer(),
        _customerSupportIconWidget(),
      ],
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
              padding: EdgeInsets.fromLTRB(20, 8, 0, 20),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SvgPicture.asset("assets/images/iconCustomerSupport.svg"),
                  if (unreadIssues != 0) ...[
                    Positioned(
                        top: -3,
                        left: 13,
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
