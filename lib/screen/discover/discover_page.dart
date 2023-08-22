//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/feed/feed_preview_page.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DiscoverPageState();
}

class DiscoverPageState extends State<DiscoverPage>
    with SingleTickerProviderStateMixin {
  bool _showFullHeader = true;
  late ScrollController _feedController;
  final _metricClient = injector<MetricClientService>();

  @override
  void initState() {
    super.initState();
    memoryValues.homePageInitialTab = HomePageTab.HOME;
    _feedController = ScrollController();
    _feedController.addListener(_scrollListener);
  }

  void _scrollListener() {
    final isShowFullHeader = _feedController.offset < 80;
    if (isShowFullHeader != _showFullHeader) {
      setState(() {
        _showFullHeader = isShowFullHeader;
      });
    }
  }

  @override
  void dispose() {
    _metricClient.addEvent(MixpanelEvent.timeViewDiscovery);
    _feedController.dispose();
    super.dispose();
  }

  void scrollToTop() {
    _feedController.animateTo(0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getDarkEmptyAppBar(),
      backgroundColor: theme.primaryColor,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              headDivider(),
              Container(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: _showFullHeader
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_showFullHeader)
                          const AutonomyLogo(
                            isWhite: true,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FeedPreviewPage(
                  controller: _feedController,
                ),
              ),
            ],
          ),
          Positioned(
              right: 26,
              bottom: 30,
              child: GestureDetector(
                onTap: () {},
                child: SvgPicture.asset(
                  "assets/images/add_icon.svg",
                  width: 34,
                  height: 34,
                ),
              ))
        ],
      ),
    );
  }
}
