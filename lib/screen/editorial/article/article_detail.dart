//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/editorial.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/screen/editorial/common/publisher_view.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/mix_panel_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/text_style_ext.dart';
import 'package:autonomy_flutter/view/markdown_view.dart';
import 'package:autonomy_flutter/view/modal_widget.dart';
import 'package:autonomy_flutter/view/number_picker.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ArticleDetailPage extends StatefulWidget {
  final EditorialPost post;

  const ArticleDetailPage({Key? key, required this.post}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage>
    with AfterLayoutMixin<ArticleDetailPage> {
  final _dio = Dio(BaseOptions(
    connectTimeout: 2000,
  ));

  late ScrollController _controller;
  final metricClient = injector.get<MetricClientService>();
  late double _selectedSize;
  late double adjustSize;
  late DateTime startReadingTime;
  bool _showHeader = true;
  Timer? _timer;
  Timer? _scrollTimer;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    startReadingTime = DateTime.now();
    _selectedSize = 16.0;
    adjustSize = _selectedSize - 16;
    _controller = ScrollController();
    _controller.addListener(_trackEventWhenScrollToEnd);
    metricClient.timerEvent(MixpanelEvent.editorialReadingArticle);
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _trackEvent();
  }

  /// Control header show/hide
  /// - When scroll, hide header
  /// - When slightly scroll up, show header, after 5s, hide header
  /// - When scroll to top, show header

  _onScroll(ScrollUpdateNotification notification) {
    if (notification.metrics.pixels < 5) {
      setState(() {
        _showHeader = true;
      });
      return;
    }

    final difference = notification.metrics.pixels - _lastOffset;
    if (difference < -25) {
      if (!_showHeader) {
        setState(() {
          _showHeader = true;
          _lastOffset = notification.metrics.pixels;
        });
      }
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          _scrollTimer?.cancel();
          setState(() {
            _showHeader = false;
            _lastOffset = notification.metrics.pixels;
          });
        }
      });
    } else if (difference > 0) {
      setState(() {
        _showHeader = false;
      });
    }
  }

  _onScrollEnd(ScrollEndNotification notification) {
    setState(() {
      _lastOffset = notification.metrics.pixels;
    });
  }

  Future<void> _updateEditorialReadingTime() async {
    const periodDuration = Duration(days: 7);

    final endReadingTime = DateTime.now();
    final readingTime =
        endReadingTime.difference(startReadingTime).inMilliseconds / 1000;
    MixpanelConfig? mixpanelConfig = metricClient.getConfig();
    if (mixpanelConfig == null) {
      mixpanelConfig = MixpanelConfig(
        editorialPeriodStart: DateTime(
            endReadingTime.year,
            endReadingTime.month,
            endReadingTime.day - (endReadingTime.weekday - 1)),
        totalEditorialReading: 0.0,
      );
      metricClient.setConfig(mixpanelConfig);
    }
    final periodStartConfig = mixpanelConfig.editorialPeriodStart;
    final periodStart = periodStartConfig ??
        DateTime(endReadingTime.year, endReadingTime.month,
            endReadingTime.day - (endReadingTime.weekday - 1));

    final currentReadingTime = mixpanelConfig.totalEditorialReading ?? 0.0;
    if (endReadingTime.difference(periodStart).compareTo(periodDuration) < 0) {
      await metricClient.setConfig(
        mixpanelConfig.copyWith(
            totalEditorialReading: currentReadingTime + readingTime),
      );
    } else {
      metricClient.addEvent(
        MixpanelEvent.editorialReadingTimeByWeek,
        data: {
          "reading_time": readingTime,
        },
      );
      await metricClient.setConfig(mixpanelConfig.copyWith(
          editorialPeriodStart: periodStart.add(periodDuration),
          totalEditorialReading: readingTime));
    }
  }

  @override
  void dispose() {
    metricClient.addEvent(MixpanelEvent.editorialReadingArticle, data: {
      "publisher": widget.post.publisher.name,
      "title": widget.post.content["title"],
    });
    _updateEditorialReadingTime();
    _controller.dispose();
    _timer?.cancel();
    _scrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    adjustSize = _selectedSize - 16;
    return Scaffold(
      appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: AppColor.primaryBlack,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          toolbarHeight: 0),
      backgroundColor: theme.colorScheme.primary,
      body: Column(
        children: [
          Visibility(
            visible: _showHeader,
            child: _header(context),
          ),
          Expanded(
            child: NotificationListener(
              child: SingleChildScrollView(
                controller: _controller,
                padding: ResponsiveLayout.pageEdgeInsets,
                child: Column(
                  children: [
                    const SizedBox(height: 32.0),
                    Visibility(
                      visible: !_showHeader,
                      child: const SizedBox(height: 50.0),
                    ),
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColor.greyMedium,
                              ),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(64))),
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          child: Text(widget.post.tag ?? "",
                              style: theme.textTheme.ppMori400Grey14
                                  .adjustSize(adjustSize)),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "originally_published_at".tr(),
                              style: theme.textTheme.ppMori400Grey12
                                  .adjustSize(adjustSize),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final website =
                                    widget.post.reference?.website.toUrl() ??
                                        "";

                                if (website.isValidUrl()) {
                                  await launchUrlString(website,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Text(
                                widget.post.reference?.website ??
                                    widget.post.publisher.name,
                                style: theme.textTheme.ppMori400SupperTeal12
                                    .adjustSize(adjustSize),
                              ),
                            )
                          ],
                        ),
                      ],
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
                                    styleSheet: editorialMarkDownStyle(context,
                                        adjustSize: adjustSize)),
                                const SizedBox(height: 50),
                                if (widget.post.reference != null)
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      border: Border.all(
                                          color: AppColor.auSuperTeal),
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
                                            style: theme
                                                .textTheme.ppMori400White12
                                                .adjustSize(adjustSize),
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
                                                widget.post.reference
                                                        ?.website ??
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
                                                  .map((e) =>
                                                      Pair(e.name, e.url))
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
                              style: theme.textTheme.ppMori400White12
                                  .adjustSize(adjustSize),
                            ));
                          } else {
                            return const Center(
                                child: CupertinoActivityIndicator());
                          }
                        },
                        future: _dio.get<String>(
                          widget.post.content["data"],
                        )),
                    const SizedBox(height: 64.0),
                  ],
                ),
              ),
              onNotification: (notification) {
                switch (notification.runtimeType) {
                  case ScrollUpdateNotification:
                    _onScroll(notification as ScrollUpdateNotification);
                    break;
                  case ScrollEndNotification:
                    _onScrollEnd(notification as ScrollEndNotification);
                    break;
                  default:
                    break;
                }
                return false;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          color: theme.colorScheme.primary,
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 12),
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
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () async {
                  await showModalBottomSheet<dynamic>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    enableDrag: false,
                    constraints: BoxConstraints(
                        maxWidth: ResponsiveLayout.isMobile
                            ? double.infinity
                            : Constants.maxWidthModalTablet),
                    barrierColor: Colors.black.withOpacity(0.5),
                    isScrollControlled: true,
                    builder: (context) {
                      return ModalSheet(
                        child: _editSize(context),
                      );
                    },
                  );
                },
                icon: SvgPicture.asset(
                  "assets/images/text_size.svg",
                  color: AppColor.white,
                  width: 32,
                  height: 32,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: closeIcon(color: theme.colorScheme.secondary),
                tooltip: "CloseArtticle",
              ),
            ],
          ),
        ),
        addOnlyDivider(color: AppColor.auGreyBackground),
      ],
    );
  }

  Widget _referenceRow(BuildContext context,
      {required String name, required String value}) {
    final theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Expanded(
          flex: 4,
          child: Text(name,
              style: theme.textTheme.ppMori400White12.adjustSize(adjustSize)),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            style: theme.textTheme.ppMori400White12.adjustSize(adjustSize),
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
          child: Text(name,
              style: theme.textTheme.ppMori400White12.adjustSize(adjustSize)),
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
                      style: theme.textTheme.ppMori400Green12
                          .adjustSize(adjustSize),
                    )))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _editSize(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            SvgPicture.asset(
              "assets/images/text_size.svg",
              width: 18,
              color: AppColor.primaryBlack,
            ),
            const SizedBox(
              width: 40,
            ),
            Text(
              "text_size".tr(),
              style: theme.textTheme.ppMori400Black14,
            ),
          ],
        ),
        const SizedBox(height: 32),
        NumberPicker(
            onChange: (value) {
              setState(() {
                _selectedSize = value;
              });
            },
            min: 12,
            max: 18,
            divisions: 6,
            value: _selectedSize,
            selectedStyle: theme.textTheme.ppMori400Black12,
            unselectedStyle: theme.textTheme.ppMori400Black12
                .copyWith(color: AppColor.primaryBlack.withOpacity(0.2))),
        const SizedBox(
          height: 40,
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
