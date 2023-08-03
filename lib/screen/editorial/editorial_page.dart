//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/editorial.dart';
import 'package:autonomy_flutter/screen/editorial/editorial_bloc.dart';
import 'package:autonomy_flutter/screen/editorial/editorial_state.dart';
import 'package:autonomy_flutter/screen/feed/feed_bloc.dart';
import 'package:autonomy_flutter/screen/feed/feed_preview_page.dart';
import 'package:autonomy_flutter/service/editorial_service.dart';
import 'package:autonomy_flutter/service/feed_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'article/article_view.dart';
import 'feralfile/exhibition_view.dart';

class EditorialPage extends StatefulWidget {
  final bool isShowDiscover;

  const EditorialPage({Key? key, this.isShowDiscover = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => EditorialPageState();
}

class EditorialPageState extends State<EditorialPage>
    with SingleTickerProviderStateMixin {
  bool _showFullHeader = true;
  late ScrollController _feedController;
  late ScrollController _editorialController;
  late TabController _tabController;
  final _metricClient = injector<MetricClientService>();
  final _feedService = injector<FeedService>();
  final _editorialService = injector<EditorialService>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.isShowDiscover ? 2 : 1,
      vsync: this,
      initialIndex: widget.isShowDiscover &&
              memoryValues.homePageInitialTab == HomePageTab.EDITORIAL
          ? 1
          : 0,
    );
    memoryValues.homePageInitialTab = HomePageTab.HOME;
    _feedController = ScrollController();
    _editorialController = ScrollController();
    _feedController.addListener(_scrollListener);
    _editorialController.addListener(_scrollListener);
    _tabController.addListener(_handleTabChange);
    _tabController.addListener(_scrollListener);
    context.read<EditorialBloc>().add(GetEditorialEvent());
  }

  void selectTab(HomePageTab tab) {
    int index = widget.isShowDiscover && tab == HomePageTab.EDITORIAL ? 1 : 0;
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
  }

  void _scrollListener() {
    final controller =
        _tabController.index == 0 ? _feedController : _editorialController;
    if (controller.positions.isEmpty) {
      return;
    }

    final isShowFullHeader = controller.offset < 80;
    if (isShowFullHeader != _showFullHeader) {
      setState(() {
        _showFullHeader = isShowFullHeader;
      });
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _trackEvent(_tabController.index);
      if (_tabController.index == 0 && widget.isShowDiscover) {
        final feedBloc = context.read<FeedBloc>();
        feedBloc.add(OpenFeedEvent());
      } else {
        final editorialBloc = context.read<EditorialBloc>();
        editorialBloc.add(OpenEditorialEvent());
      }
    }
  }

  void _trackEvent(int index) {
    if (index == 0 && widget.isShowDiscover) {
      _metricClient.addEvent(MixpanelEvent.timeViewEditorial);
      _metricClient.addEvent(MixpanelEvent.viewDiscovery);
      _metricClient.timerEvent(MixpanelEvent.timeViewDiscovery);
    } else {
      _metricClient.addEvent(MixpanelEvent.timeViewDiscovery);
      _metricClient.addEvent(MixpanelEvent.viewEditorial);
      _metricClient.timerEvent(MixpanelEvent.timeViewEditorial);
    }
  }

  @override
  void dispose() {
    if (widget.isShowDiscover && _tabController.index == 0) {
      _metricClient.addEvent(MixpanelEvent.timeViewDiscovery);
    } else {
      _metricClient.addEvent(MixpanelEvent.timeViewEditorial);
    }
    _editorialController.dispose();
    _feedController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void scrollToTop() {
    final controller =
        _tabController.index == 0 ? _feedController : _editorialController;
    controller.animateTo(0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getDarkEmptyAppBar(),
      backgroundColor: theme.primaryColor,
      body: Column(
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
                    Hero(
                      tag: "discover_tab",
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (widget.isShowDiscover) ...[
                                _tabWidget(
                                    title: 'discover'.tr(),
                                    unread: _feedService.unviewedCount),
                              ],
                              _tabWidget(
                                  title: 'editorial'.tr(),
                                  unread: _editorialService.unviewedCount),
                            ],
                          ),
                          TabBar(
                            controller: _tabController,
                            indicatorSize: TabBarIndicatorSize.label,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 5.0,
                              vertical: 6.0,
                            ).copyWith(bottom: 0),
                            labelStyle: theme.textTheme.ppMori400White14,
                            unselectedLabelStyle:
                                theme.textTheme.ppMori400Grey14,
                            isScrollable: true,
                            indicator: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppColor.auSuperTeal),
                              ),
                            ),
                            tabs: [
                              if (widget.isShowDiscover) ...[
                                Text(
                                  'discover'.tr(),
                                  style: const TextStyle(height: 0.8),
                                ),
                              ],
                              Text(
                                'editorial'.tr(),
                                style: const TextStyle(height: 0.8),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                if (widget.isShowDiscover) ...[
                  FeedPreviewPage(
                    controller: _feedController,
                  ),
                ],
                BlocBuilder<EditorialBloc, EditorialState>(
                    builder: (context, state) {
                  return ListView.builder(
                    controller: _editorialController,
                    itemCount: state.editorial.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 32, bottom: 32),
                        child: _postSection(state.editorial[index]),
                      );
                    },
                  );
                })
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unreadIcon(int unreadCount) {
    if (unreadCount == 0) {
      return const SizedBox();
    }
    return Container(
      padding: const EdgeInsets.only(
        left: 3,
        right: 3,
      ),
      height: 11,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(50),
      ),
      constraints: const BoxConstraints(minWidth: 11),
      child: Center(
        child: Text(
          "$unreadCount",
          style: Theme.of(context).textTheme.ppMori700White12.copyWith(
                fontSize: 8,
              ),
          overflow: TextOverflow.visible,
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _tabWidget(
      {required String title, required ValueNotifier<int> unread}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 5.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Align(
              alignment: Alignment.bottomRight,
              child: ValueListenableBuilder(
                valueListenable: unread,
                builder: (BuildContext context, int value, Widget? child) {
                  return _unreadIcon(value);
                },
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColor.greyMedium),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 2),
              child: Text(
                title,
                style: theme.textTheme.ppMori400Grey14
                    .copyWith(height: 0.8, color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _postSection(EditorialPost post) {
    switch (post.type) {
      case "Collection":
        final exhibitionId = post.content["exhibition_id"];
        if (exhibitionId != null) {
          return ExhibitionView(
              id: post.content["exhibition_id"],
              publisher: post.publisher,
              tag: post.tag ?? "");
        } else {
          return const SizedBox();
        }
      case "Article":
        return Padding(
          padding: ResponsiveLayout.pageHorizontalEdgeInsets,
          child: ArticleView(post: post),
        );
      default:
        return const SizedBox();
    }
  }
}
