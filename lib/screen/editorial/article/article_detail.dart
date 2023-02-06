//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/editorial.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/screen/editorial/common/publisher_view.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/markdown_view.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ArticleDetailPage extends StatefulWidget {
  final EditorialPost post;

  const ArticleDetailPage({Key? key, required this.post}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  final _dio = Dio(BaseOptions(
    connectTimeout: 2000,
  ));

  late ScrollController _controller;
  final metricClient = injector.get<MetricClientService>();

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _controller.addListener(_trackEventWhenScrollToEnd);
    _trackEvent();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      backgroundColor: theme.colorScheme.primary,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: SingleChildScrollView(
              controller: _controller,
              padding: ResponsiveLayout.pageEdgeInsets,
              child: Column(
                children: [
                  const SizedBox(height: 32.0),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColor.greyMedium,
                          ),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(64))),
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 8.0),
                      child: Text(widget.post.tag ?? "",
                          style: theme.textTheme.ppMori400Grey14),
                    ),
                  ),
                  const SizedBox(height: 32.0),
                  FutureBuilder<Response<String>>(
                      builder: (context, snapshot) {
                        if (snapshot.hasData &&
                            snapshot.data?.statusCode == 200) {
                          return Column(
                            children: [
                              AuMarkdown(
                                  data: snapshot.data!.data!,
                                  styleSheet: editorialMarkDownStyle(context)),
                              const SizedBox(height: 50),
                              if (widget.post.reference != null)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    border:
                                        Border.all(color: AppColor.auSuperTeal),
                                  ),
                                  padding: const EdgeInsets.all(15.0),
                                  child: Column(
                                    children: [
                                      if (widget.post.tag == "Essay") ...[
                                        PublisherView(
                                            publisher: widget.post.publisher),
                                        const SizedBox(height: 10.0),
                                        Text(
                                          widget.post.publisher.intro ?? "",
                                          style:
                                              theme.textTheme.ppMori400White12,
                                        ),
                                        const SizedBox(height: 32.0),
                                      ],
                                      _referenceRow(
                                        context,
                                        name: "location".tr(),
                                        value:
                                            widget.post.reference?.location ??
                                                "",
                                      ),
                                      const Divider(
                                          height: 20,
                                          color: AppColor.greyMedium),
                                      _referenceRowWithLinks(
                                        context,
                                        name: "web".tr(),
                                        links: [
                                          Pair(
                                              widget.post.reference?.website ??
                                                  "",
                                              widget.post.reference?.website
                                                      .toUrl() ??
                                                  "")
                                        ],
                                      ),
                                      const Divider(
                                          height: 20,
                                          color: AppColor.greyMedium),
                                      _referenceRowWithLinks(
                                        context,
                                        name: "social".tr(),
                                        links: widget.post.reference?.socials
                                                .map((e) => Pair(e.name, e.url))
                                                .toList() ??
                                            [],
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        } else if (snapshot.hasError ||
                            (snapshot.data != null &&
                                snapshot.data?.statusCode != 200)) {
                          return Center(
                              child: Text(
                            "error_loading_content".tr(),
                            style: theme.textTheme.ppMori400White12,
                          ));
                        } else {
                          return const Center(
                              child: CupertinoActivityIndicator());
                        }
                      },
                      future: _dio.get<String>(
                        widget.post.content["data"],
                      )
                      //'https://raw.githubusercontent.com/ppupha/Bitmark/main/README.md'),
                      ),
                  const SizedBox(height: 64.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.primary,
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PublisherView(
                  publisher: widget.post.publisher,
                  isLargeSize: true,
                ),
                const SizedBox(height: 10.0),
                Text(
                  widget.post.content["title"],
                  style: theme.textTheme.ppMori400White16,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(width: 50.0),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: closeIcon(color: theme.colorScheme.secondary),
            tooltip: "CloseArtticle",
          ),
        ],
      ),
    );
  }

  Widget _referenceRow(BuildContext context,
      {required String name, required String value}) {
    final theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Expanded(
          flex: 4,
          child: Text(name, style: theme.textTheme.ppMori400White12),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            style: theme.textTheme.ppMori400White12,
          ),
        ),
      ],
    );
  }

  Widget _referenceRowWithLinks(BuildContext context,
      {required String name, required List<Pair<String, String>> links}) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 4,
          child: Text(name, style: theme.textTheme.ppMori400White12),
        ),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: links
                .map((e) => GestureDetector(
                    onTap: () {
                      launchUrl(Uri.parse(e.second),
                          mode: LaunchMode.externalApplication);
                      metricClient
                          .addEvent(MixpanelEvent.tabOnLinkInEditorial, data: {
                        'name': name,
                        'link': e.second,
                      });
                    },
                    child: Text(
                      e.first,
                      style: theme.textTheme.ppMori400Green12,
                    )))
                .toList(),
          ),
        ),
      ],
    );
  }

  void _trackEvent() {
    metricClient.addEvent(MixpanelEvent.editorialViewArticle, data: {
      "publisher": widget.post.publisher.name,
      "title": widget.post.content["title"],
    });
  }

  void _trackEventWhenScrollToEnd() {
    final isEnd =
        _controller.position.atEdge && (_controller.position.pixels != 0);
    if (isEnd) {
      metricClient.addEvent(MixpanelEvent.finishArticles, data: {
        "publisher": widget.post.publisher.name,
        "title": widget.post.content["title"],
      });
    }
  }
}
