//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/discover/following_page.dart';
import 'package:autonomy_flutter/screen/feed/feed_preview_page.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/add_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:flutter/material.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DiscoverPageState();
}

class DiscoverPageState extends State<DiscoverPage>
    with SingleTickerProviderStateMixin {
  bool _showFullHeader = true;
  bool _showToFollowPage = true;
  late ScrollController _feedController;
  final _metricClient = injector<MetricClientService>();
  double _offset = 0.0;

  @override
  void initState() {
    super.initState();
    memoryValues.homePageInitialTab = HomePageTab.HOME;
    _feedController = ScrollController();
    _feedController.addListener(_scrollListener);
  }

  void _scrollListener() {
    bool stateChanged = false;
    if (_offset < _feedController.offset) {
      // scroll down
      if (_showToFollowPage) {
        _showToFollowPage = false;
        stateChanged = true;
      }
    } else {
      // scroll up
      if (!_showToFollowPage) {
        _showToFollowPage = true;
        stateChanged = true;
      }
    }
    final isShowFullHeader = _feedController.offset < 80;
    if (isShowFullHeader != _showFullHeader) {
      stateChanged = true;
      _showFullHeader = isShowFullHeader;
      _showToFollowPage = true;
    }
    if (stateChanged) {
      setState(() {});
    }
    _offset = _feedController.offset;
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
              child: Visibility(
                visible: _showToFollowPage,
                child: AddButton(
                    size: 36,
                    onTap: () {
                      Navigator.pushNamed(context, FollowingPage.tag);
                    }),
              ))
        ],
      ),
    );
  }
}
