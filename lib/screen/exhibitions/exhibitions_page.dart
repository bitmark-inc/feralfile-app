import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_state.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_page.dart';
import 'package:autonomy_flutter/screen/exhibitions/exhibitions_bloc.dart';
import 'package:autonomy_flutter/screen/exhibitions/exhibitions_state.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/feralfile_artist_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sentry/sentry.dart';

class ExhibitionsPage extends StatefulWidget {
  const ExhibitionsPage({super.key});

  @override
  State<ExhibitionsPage> createState() => ExhibitionsPageState();
}

class ExhibitionsPageState extends State<ExhibitionsPage> with RouteAware {
  late ExhibitionBloc _exhibitionBloc;
  late ScrollController _controller;
  final _navigationService = injector<NavigationService>();
  static const _padding = 14.0;
  static const _exhibitionInfoDivideWidth = 20.0;
  String? _autoOpenExhibitionId;

  // initState
  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _exhibitionBloc = injector<ExhibitionBloc>();
    _exhibitionBloc.add(GetAllExhibitionsEvent());
  }

  void scrollToTop() {
    unawaited(_controller.animateTo(0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn));
  }

  @override
  void dispose() {
    _controller.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    refreshExhibitions();
  }

  void refreshExhibitions() {
    _exhibitionBloc.add(GetAllExhibitionsEvent());
  }

  void setAutoOpenExhibition(String exhibitionId) {
    setState(() {
      _autoOpenExhibitionId = exhibitionId;
    });
    if (_exhibitionBloc.state.allExhibitions.isNotEmpty) {
      _openExhibition(context, exhibitionId);
    }
  }

  void _openExhibition(BuildContext context, String exhibitionId) {
    final listExhibitions = _exhibitionBloc.state.allExhibitions;
    final index =
        listExhibitions.indexWhere((element) => element.id == exhibitionId);
    if (index < 0) {
      unawaited(Sentry.captureMessage('Exhibition not found: $exhibitionId'));
    } else {
      unawaited(
        _navigationService.navigateTo(
          AppRouter.exhibitionDetailPage,
          arguments: ExhibitionDetailPayload(
            exhibitions: listExhibitions,
            index: index,
          ),
        ),
      );
    }
    _autoOpenExhibitionId = null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: getDarkEmptyAppBar(Colors.transparent),
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: AppColor.primaryBlack,
        body: CustomScrollView(
          controller: _controller,
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.top,
              ),
            ),
            SliverToBoxAdapter(
              child: HeaderView(
                title: 'exhibitions'.tr(),
              ),
            ),
            _listExhibitions(context),
          ],
        ),
      );

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

  Widget _listExhibitions(BuildContext context) =>
      BlocConsumer<ExhibitionBloc, ExhibitionsState>(
        listener: (context, exhibitionsState) {
          if (exhibitionsState.allExhibitions.isNotEmpty &&
              _autoOpenExhibitionId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _openExhibition(context, _autoOpenExhibitionId!);
            });
          }
        },
        builder: (context, exhibitionsState) =>
            BlocBuilder<SubscriptionBloc, SubscriptionState>(
          builder: (context, subscriptionState) {
            if (exhibitionsState.currentPage == 0) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    backgroundColor: AppColor.auQuickSilver,
                    strokeWidth: 2,
                  ),
                ),
              );
            } else {
              final featureExhibition = exhibitionsState.featuredExhibition;
              final upcomingExhibition = exhibitionsState.upcomingExhibition;
              final ongoingExhibitions = exhibitionsState.ongoingExhibitions;
              final pastExhibitions = exhibitionsState.pastExhibitions;

              final allExhibition = exhibitionsState.allExhibitions;

              final divider = addDivider(
                  height: 40, color: AppColor.auQuickSilver, thickness: 0.5);
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: _padding),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final exhibition = allExhibition[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (featureExhibition != null && index == 0) ...[
                            _exhibitionGroupHeader(
                              context,
                              'current_exhibition'.tr(),
                            ),
                          ],
                          if (upcomingExhibition != null && index == 1) ...[
                            _exhibitionGroupHeader(
                              context,
                              'upcoming_exhibition'.tr(),
                            ),
                          ],
                          if (exhibition.id ==
                              ongoingExhibitions?.firstOrNull?.id) ...[
                            _exhibitionGroupHeader(
                              context,
                              'on_going_exhibition'.tr(),
                            ),
                          ],
                          if (exhibition.id == pastExhibitions?.first.id)
                            _exhibitionGroupHeader(
                              context,
                              'past_exhibition'.tr(),
                            ),
                          _exhibitionItem(
                            context: context,
                            viewableExhibitions: allExhibition,
                            exhibition: exhibition,
                            isFeaturedExhibition:
                                exhibition.id == featureExhibition?.id,
                          ),
                          divider,
                          if (index == allExhibition.length - 1)
                            const SizedBox(height: 40),
                        ],
                      );
                    },
                    childCount: allExhibition.length,
                  ),
                ),
              );
            }
          },
        ),
      );

  Widget _exhibitionGroupHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.ppMori700White14,
              ),
            ],
          ),
        ],
      ),
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
}
