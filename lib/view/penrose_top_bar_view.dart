//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum PenroseTopBarViewStyle {
  main,
  back,
  settings,
}

class PenroseTopBarView extends StatefulWidget {
  final ScrollController scrollController;
  final PenroseTopBarViewStyle style;

  const PenroseTopBarView(this.scrollController, this.style, {Key? key})
      : super(key: key);

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

  @override
  void didPop() {
    widget.scrollController.removeListener(_scrollListener);
  }

  @override
  void didPushNext() {
    // Reset to normal SystemUIMode
    if (Platform.isIOS) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
    }
  }

  _scrollListener() {
    if (widget.scrollController.positions.isEmpty) {
      // ScrollController not attached to any scroll views.
      return;
    }

    final breakpoint =
        widget.style == PenroseTopBarViewStyle.settings ? 25 : 80;

    if (widget.scrollController.offset > breakpoint) {
      if (Platform.isIOS) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
      setState(() {
        _opacity = 0;
      });
    } else {
      if (Platform.isIOS) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
            overlays: SystemUiOverlay.values);
      }
      setState(() {
        _opacity = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        builder: (context, value) => Stack(children: [
          Opacity(opacity: _opacity, child: _headerWidget(context)),
        ]),
        animation: widget.scrollController,
      ),
    );
  }

  Widget _headerWidget(BuildContext context) {
    switch (widget.style) {
      case PenroseTopBarViewStyle.main:
        return Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.fromLTRB(7, 0, 2, 90),
          child: _mainHeaderWidget(context, isInSettingsPage: false),
        );
      case PenroseTopBarViewStyle.settings:
        return Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.fromLTRB(7, 0, 2, 90),
          child: _mainHeaderWidget(context, isInSettingsPage: true),
        );
      case PenroseTopBarViewStyle.back:
        return Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 90),
          child: _backHeaderWidget(context),
        );
    }
  }

  Widget _backHeaderWidget(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 7, 18, 8),
        child: Row(
          children: [
            Row(
              children: [
                SvgPicture.asset('assets/images/nav-arrow-left.svg'),
                const SizedBox(width: 7),
                Text(
                  "back".tr(),
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mainHeaderWidget(BuildContext context,
      {required bool isInSettingsPage}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 47),
        Visibility(
          visible: isInSettingsPage,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
            child: Text(
              "settings".tr().toUpperCase(),
              style: theme.textTheme.labelLarge,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
          child: Semantics(
            label: isInSettingsPage ? "close_icon" : "Settings",
            child: IconButton(
              onPressed: () {
                if (_opacity == 0) return;
                if (isInSettingsPage) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushNamed(AppRouter.settingsPage);
                }
              },
              icon: isInSettingsPage ? closeIcon() : _settingIcon(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _settingIcon() {
    final configService = injector<ConfigurationService>();
    final hasPendingSettings = configService.hasPendingSettings() ||
        configService.shouldShowSubscriptionHint();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SvgPicture.asset('assets/images/userOutlinedIcon.svg'),
        if (hasPendingSettings) ...[
          Positioned(
              top: -1,
              left: 14,
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColor.red,
                  ),
                ),
              )),
        ]
      ],
    );
  }
}
