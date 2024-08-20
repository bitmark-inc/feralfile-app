import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_page.dart';
import 'package:autonomy_flutter/screen/feralfile_home/filter_bar.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/feralfile_artist_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/loading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/svg.dart';

class ExploreExhibition extends StatefulWidget {
  final String? searchText;
  final Map<FilterType, FilterValue> filters;
  final SortBy sortBy;

  const ExploreExhibition(
      {required this.filters,
      required this.sortBy,
      this.searchText,
      super.key});

  @override
  State<ExploreExhibition> createState() => ExploreExhibitionState();

  bool isEqual(Object other) =>
      other is ExploreExhibition &&
      other.searchText == searchText &&
      other.filters == filters &&
      other.sortBy == sortBy;
}

class ExploreExhibitionState extends State<ExploreExhibition> {
  List<Exhibition>? _exhibitions;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    unawaited(_fetchExhibitions(context));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ExploreExhibition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isEqual(widget) || true) {
      unawaited(_fetchExhibitions(context));
    }
  }

  void scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Widget _loadingView(BuildContext context) => const Padding(
        padding: EdgeInsets.only(bottom: 100),
        child: LoadingWidget(),
      );

  Widget _emptyView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        'No exhibitions found',
        style: theme.textTheme.ppMori400White14,
      ),
    );
  }

  Widget _exhibitionView(BuildContext context, List<Exhibition> exhibitions) =>
      ListExhibitionView(
          scrollController: _scrollController,
          exhibitions: exhibitions,
          padding: const EdgeInsets.only(bottom: 100));

  @override
  Widget build(BuildContext context) {
    if (_exhibitions == null) {
      return _loadingView(context);
    } else if (_exhibitions!.isEmpty) {
      return _emptyView(context);
    } else {
      return Expanded(child: _exhibitionView(context, _exhibitions!));
    }
  }

  Future<List<Exhibition>> _fetchExhibitions(BuildContext context,
      {int offset = 0, int pageSize = 20}) async {
    final sortBy = widget.sortBy;
    final exhibitions = await injector<FeralFileService>().getAllExhibitions(
      keywork: widget.searchText ?? '',
      offset: offset,
      limit: pageSize,
      sortBy: sortBy.queryParam,
      sortOrder: sortBy.sortOrder.queryParam,
      filters: widget.filters,
    );
    setState(() {
      _exhibitions = exhibitions;
    });
    return exhibitions;
  }

  Future<void> _loadMoreExhibitions(BuildContext context,
      {int offset = 0, int pageSize = 20}) async {
    final sortBy = widget.sortBy;
    final exhibitions = await injector<FeralFileService>().getAllExhibitions(
      keywork: widget.searchText ?? '',
      offset: offset,
      limit: pageSize,
      sortBy: sortBy.queryParam,
      sortOrder: sortBy.sortOrder.queryParam,
      filters: widget.filters,
    );
    setState(() {
      _exhibitions ??= [];
      _exhibitions?.addAll(exhibitions);
    });
  }
}

class ListExhibitionView extends StatefulWidget {
  final List<Exhibition> exhibitions;
  final ScrollController? scrollController;
  final bool isScrollable;
  final EdgeInsets padding;

  const ListExhibitionView({
    required this.exhibitions,
    this.scrollController,
    super.key,
    this.isScrollable = true,
    this.padding = const EdgeInsets.all(0),
  });

  @override
  State<ListExhibitionView> createState() => _ListExhibitionViewState();
}

class _ListExhibitionViewState extends State<ListExhibitionView> {
  final _navigationService = injector<NavigationService>();
  static const _padding = 12.0;
  static const _exhibitionInfoDivideWidth = 20.0;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    final divider =
        addDivider(height: 40, color: AppColor.auQuickSilver, thickness: 0.5);
    return CustomScrollView(
      controller: _scrollController,
      shrinkWrap: true,
      physics: widget.isScrollable
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: widget.padding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final exhibition = widget.exhibitions[index];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _padding),
                      child: _exhibitionItem(
                          context: context,
                          viewableExhibitions: widget.exhibitions,
                          exhibition: exhibition,
                          isFeaturedExhibition: false),
                    ),
                    if (index != widget.exhibitions.length - 1) divider,
                  ],
                );
              },
              childCount: widget.exhibitions.length,
            ),
          ),
        )
      ],
    );
  }

  Future<void> _onExhibitionTap(BuildContext context,
      List<Exhibition> viewableExhibitions, int index) async {
    if (index >= 0) {
      await Navigator.of(context).pushNamed(
        AppRouter.exhibitionDetailPage,
        arguments: ExhibitionDetailPayload(
          exhibitions: viewableExhibitions,
          index: index,
        ),
      );
    }
  }

  Widget _exhibitionItem({
    required BuildContext context,
    required List<Exhibition> viewableExhibitions,
    required Exhibition exhibition,
    required bool isFeaturedExhibition,
  }) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final estimatedHeight = (screenWidth - _padding * 2) / 16 * 9;
    final estimatedWidth = screenWidth - _padding * 2;
    final index = viewableExhibitions.indexOf(exhibition);
    final titleStyle = theme.textTheme.ppMori400White16;
    final subTitleStyle = theme.textTheme.ppMori400Grey12;
    return GestureDetector(
      onTap: () async => _onExhibitionTap(context, viewableExhibitions, index),
      behavior: HitTestBehavior.deferToChild,
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: exhibition.id == SOURCE_EXHIBITION_ID
                  ? SvgPicture.network(
                      exhibition.coverUrl,
                      height: estimatedHeight,
                      placeholderBuilder: (context) => Container(
                        height: estimatedHeight,
                        width: estimatedWidth,
                        color: Colors.transparent,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            backgroundColor: AppColor.auQuickSilver,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: exhibition.coverUrl,
                      height: estimatedHeight,
                      maxWidthDiskCache: estimatedWidth.toInt(),
                      memCacheWidth: estimatedWidth.toInt(),
                      memCacheHeight: estimatedHeight.toInt(),
                      maxHeightDiskCache: estimatedHeight.toInt(),
                      cacheManager: injector<CacheManager>(),
                      placeholder: (context, url) => Container(
                        height: estimatedHeight,
                        width: estimatedWidth,
                        color: Colors.transparent,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            backgroundColor: AppColor.auQuickSilver,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      fit: BoxFit.fitWidth,
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: (estimatedWidth - _exhibitionInfoDivideWidth) / 2,
                  child: AutoSizeText(
                    exhibition.title,
                    style: titleStyle,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: _exhibitionInfoDivideWidth),
                Expanded(
                  child: GestureDetector(
                    onTap: () {},
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (exhibition.isSoloExhibition &&
                            exhibition.artists != null) ...[
                          RichText(
                            text: TextSpan(
                              style: subTitleStyle.copyWith(
                                  decorationColor: AppColor.disabledColor),
                              children: [
                                TextSpan(text: 'works_by'.tr()),
                                TextSpan(
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () async {
                                        await _navigationService
                                            .openFeralFileArtistPage(
                                          exhibition.artists![0].alias,
                                        );
                                      },
                                    text: exhibition.artists![0].displayAlias,
                                    style: const TextStyle(
                                      decoration: TextDecoration.underline,
                                    )),
                              ],
                            ),
                          ),
                        ],
                        if (exhibition.curator != null)
                          RichText(
                            text: TextSpan(
                              style: subTitleStyle.copyWith(
                                  decorationColor: AppColor.disabledColor),
                              children: [
                                TextSpan(text: 'curated_by'.tr()),
                                TextSpan(
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      await _navigationService
                                          .openFeralFileCuratorPage(
                                              exhibition.curator!.alias);
                                    },
                                  text: exhibition.curator!.displayAlias,
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          exhibition.isGroupExhibition
                              ? 'group_exhibition'.tr()
                              : 'solo_exhibition'.tr(),
                          style: subTitleStyle,
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
