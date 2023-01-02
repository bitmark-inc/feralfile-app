//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/editorial.dart';
import 'package:autonomy_flutter/screen/editorial/editorial_bloc.dart';
import 'package:autonomy_flutter/screen/editorial/editorial_state.dart';
import 'package:autonomy_flutter/screen/feed/feed_preview_page.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'article/article_view.dart';
import 'feralfile/exhibition_view.dart';

class EditorialPage extends StatefulWidget {
  final bool isShowDiscover;

  const EditorialPage({Key? key, this.isShowDiscover = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _EditorialPageState();
}

class _EditorialPageState extends State<EditorialPage>
    with SingleTickerProviderStateMixin {
  bool _showFullHeader = true;
  late ScrollController _feedController;
  late ScrollController _editorialController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.isShowDiscover ? 2 : 1,
      vsync: this,
    );
    _feedController = ScrollController();
    _editorialController = ScrollController();
    _feedController.addListener(_scrollListener);
    _editorialController.addListener(_scrollListener);
    _tabController.addListener(_scrollListener);
    context.read<EditorialBloc>().add(GetEditorialEvent());
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

  @override
  void dispose() {
    _editorialController.dispose();
    _feedController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      backgroundColor: theme.primaryColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Row(
                  mainAxisAlignment: _showFullHeader
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_showFullHeader)
                      SvgPicture.asset(
                        "assets/images/autonomy_icon_white.svg",
                        width: 50,
                        height: 50,
                      ),
                    Hero(
                      tag: "discover_tab",
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (widget.isShowDiscover) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5.0,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.only(top: 5),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                            color: AppColor.greyMedium),
                                      ),
                                    ),
                                    child: Text(
                                      'discover'.tr(),
                                      style: theme.textTheme.ppMori400Grey14
                                          .copyWith(
                                        height: 0.8,
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5.0,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.only(top: 5),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                          color: AppColor.greyMedium),
                                    ),
                                  ),
                                  child: Text(
                                    'editorial'.tr(),
                                    style: theme.textTheme.ppMori400Grey14
                                        .copyWith(
                                            height: 0.8,
                                            color: Colors.transparent),
                                  ),
                                ),
                              ),
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
                        padding: const EdgeInsets.only(bottom: 64),
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
