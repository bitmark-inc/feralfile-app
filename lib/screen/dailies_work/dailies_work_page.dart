import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/dailies.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_user.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_bloc.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_state.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_widget.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_page.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/cast_button.dart';
import 'package:autonomy_flutter/view/daily_progress_bar.dart';
import 'package:autonomy_flutter/view/exhibition_item.dart';
import 'package:autonomy_flutter/view/important_note_view.dart';
import 'package:autonomy_flutter/view/keep_alive_widget.dart';
import 'package:autonomy_flutter/view/loading.dart';
import 'package:autonomy_flutter/view/user_widget.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:url_launcher/url_launcher.dart';

class DailyWorkPage extends StatefulWidget {
  const DailyWorkPage({super.key});

  @override
  State<DailyWorkPage> createState() => DailyWorkPageState();
}

class DailyWorkPageState extends State<DailyWorkPage>
    with AutomaticKeepAliveClientMixin, RouteAware {
  Timer? _timer;
  Duration? _remainingDuration;
  Timer? _progressTimer;
  PageController? _pageController;
  late int _currentIndex;
  ScrollController? _scrollController;
  final _artworkKey = GlobalKey<ArtworkPreviewWidgetState>();

  @override
  void initState() {
    super.initState();
    context.read<DailyWorkBloc>().add(GetDailyAssetTokenEvent());
    _pageController = PageController();
    _pageController!.addListener(() {
      _pageControllerListenser();
    });
    _currentIndex = _pageController!.initialPage;
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressTimer?.cancel();
    _pageController?.dispose();
    _scrollController?.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _pageControllerListenser() {
    if (_pageController!.page != 0) {
      pauseDailyWork();
    } else {
      resumeDailyWork();
    }
  }

  Future<void> scheduleNextDailyWork(BuildContext context) async {
    setState(() {
      _remainingDuration = _calcRemainingDuration;
    });
    const defaultDuration = Duration(hours: 1);
    final nextDailyDuration = _calcRemainingDuration;
    final duration = nextDailyDuration > defaultDuration
        ? defaultDuration
        : nextDailyDuration;
    _timer?.cancel();
    _timer = Timer(duration, () {
      log.info('Get Daily Asset Token');
      context.read<DailyWorkBloc>().add(GetDailyAssetTokenEvent());
    });
  }

  DateTime get _nextDailyDateTime {
    const defaultScheduleTime = 6;
    final configScheduleTime = injector<RemoteConfigService>()
        .getConfig<String>(ConfigGroup.daily, ConfigKey.scheduleTime,
            defaultScheduleTime.toString());
    final now =
        DateTime.now().subtract(Duration(hours: int.parse(configScheduleTime)));
    final startNextDay = DateTime(now.year, now.month, now.day + 1).add(
      Duration(hours: int.parse(configScheduleTime), seconds: 3),
      // add 3 seconds to avoid the same artwork
    );
    return startNextDay;
  }

  void pauseDailyWork() {
    _artworkKey.currentState?.pause();
    muteDailyWork();
  }

  void resumeDailyWork() {
    _artworkKey.currentState?.resume();
    unmuteDailyWork();
  }

  void muteDailyWork() {
    _artworkKey.currentState?.mute();
  }

  void unmuteDailyWork() {
    _artworkKey.currentState?.unmute();
  }

  void scrollToTop() {
    unawaited(_pageController?.animateToPage(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut));
  }

  Duration? get _calcTotalDuration => const Duration(hours: 24);

  Duration get _calcRemainingDuration =>
      _nextDailyDateTime.difference(DateTime.now());

  void updateProgressStatus() {
    _progressTimer?.cancel();
    // Update After Each 5 Minutes
    final remainingDuration = _calcRemainingDuration;
    final timerDuration = remainingDuration.inHours >= 1
        ? const Duration(minutes: 5)
        : remainingDuration.inMinutes >= 1
            ? const Duration(minutes: 1)
            : const Duration(seconds: 3);
    _progressTimer = Timer(timerDuration, () {
      setState(() {
        _remainingDuration = _calcRemainingDuration;
      });
      updateProgressStatus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: AppColor.primaryBlack,
      appBar: getDarkEmptyAppBar(Colors.transparent),
      body: _buildBody(),
    );
  }

  Widget _buildBody() => BlocBuilder<DailyWorkBloc, DailiesWorkState>(
        builder: (context, state) => PageView(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          children: [
            KeepAliveWidget(child: _dailyPreview()),
            KeepAliveWidget(child: _dailyDetails(context)),
          ],
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      );

  Widget _header(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text('daily_work'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .ppMori700Black36
                    .copyWith(color: AppColor.white),
                textAlign: TextAlign.left),
          ),
          FFCastButton(
            displayKey: CastDailyWorkRequest.displayKey,
            onDeviceSelected: (device) {
              context.read<CanvasDeviceBloc>().add(
                  CanvasDeviceCastDailyWorkEvent(
                      device, CastDailyWorkRequest()));
            },
            text: 'display'.tr(),
            shouldCheckSubscription: false,
          ),
        ],
      );

  Widget _progressBar(BuildContext context, Duration remainingDuration,
      Duration totalDuration) {
    final progress = 1 - remainingDuration.inSeconds / totalDuration.inSeconds;
    return Row(
      children: [
        Expanded(
          child: ProgressBar(
            progress: progress,
          ),
        ),
        const SizedBox(width: 32),
        Text(
          _nextDailyDurationText(remainingDuration),
          style: Theme.of(context).textTheme.ppMori400Grey12,
        ),
      ],
    );
  }

  String _nextDailyDurationText(Duration remainingDuration) {
    final hours = remainingDuration.inHours;
    if (hours > 0) {
      return 'next_daily'.tr(namedArgs: {
        'duration': '${hours}hr',
      });
    } else {
      final minutes = remainingDuration.inMinutes;
      if (minutes <= 1) {
        return 'next_daily'.tr(namedArgs: {
          'duration': 'in a minute',
        });
      } else {
        return 'next_daily'.tr(namedArgs: {
          'duration': '$minutes mins',
        });
      }
    }
  }

  Widget _artworkInfoIcon() => Semantics(
        label: 'artworkInfoIcon',
        child: GestureDetector(
          onTap: () {
            _currentIndex == 0
                ? unawaited(_pageController?.animateToPage(1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut))
                : unawaited(_pageController?.animateToPage(0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut));
          },
          child: Container(
            padding: const EdgeInsets.only(top: 8, bottom: 8, left: 8),
            child: SvgPicture.asset(
              _currentIndex == 0
                  ? 'assets/images/info_white.svg'
                  : 'assets/images/info_white_active.svg',
              width: 22,
              height: 22,
            ),
          ),
        ),
      );

  Widget _dailyPreview() => Column(
        children: [
          SizedBox(
            height: MediaQuery.paddingOf(context).top + 32,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _header(context),
          ),
          Expanded(
            child: BlocConsumer<DailyWorkBloc, DailiesWorkState>(
              listener: (context, state) {
                if (state.assetTokens.isNotEmpty) {
                  // get identity
                  final identitiesList = <String>[];
                  final assetToken = state.assetTokens.first;
                  identitiesList
                    ..add(assetToken.artistName!)
                    ..add(assetToken.owner);
                  context
                      .read<IdentityBloc>()
                      .add(GetIdentityEvent(identitiesList));
                  unawaited(scheduleNextDailyWork(context));
                  updateProgressStatus();
                }
              },
              builder: (context, state) {
                final assetToken = state.assetTokens.firstOrNull;
                if (assetToken == null) {
                  return const LoadingWidget();
                }
                return Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: IgnorePointer(
                          child: ArtworkPreviewWidget(
                            key: _artworkKey,
                            useIndexer: true,
                            identity: ArtworkIdentity(
                              assetToken.id,
                              assetToken.owner,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_remainingDuration != null &&
                        _calcTotalDuration != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _progressBar(
                          context,
                          _remainingDuration!,
                          _calcTotalDuration!,
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: _tokenInfo(
                        context,
                        assetToken,
                      ),
                    )
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 100),
        ],
      );

  Widget _tokenInfo(BuildContext context, AssetToken assetToken) {
    final identityState = context.watch<IdentityBloc>().state;
    final artistName =
        assetToken.artistName?.toIdentityOrMask(identityState.identityMap) ??
            assetToken.artistID ??
            '';
    return Row(
      children: [
        Expanded(
          child: ArtworkDetailsHeader(
            title: assetToken.displayTitle ?? '',
            subTitle: artistName,
            onSubTitleTap: assetToken.artistID != null && assetToken.isFeralfile
                ? () => unawaited(injector<NavigationService>()
                    .openFeralFileArtistPage(assetToken.artistID!))
                : null,
          ),
        ),
        _artworkInfoIcon(),
      ],
    );
  }

  Widget _dailyDetails(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    return BlocBuilder<DailyWorkBloc, DailiesWorkState>(
      builder: (context, state) {
        final assetToken = state.assetTokens.firstOrNull;
        if (assetToken == null) {
          return loadingIndicator();
        }
        final identityState = context.watch<IdentityBloc>().state;
        final artistName = assetToken.artistName
                ?.toIdentityOrMask(identityState.identityMap) ??
            assetToken.artistID ??
            '';
        return NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction == ScrollDirection.forward &&
                _scrollController!.offset < 10) {
              unawaited(_pageController?.animateToPage(0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut));
            }
            return true;
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + 48,
                ),
              ),
              if (state.currentDailyToken != null &&
                  state.currentExhibition != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _mediumDescription(context, state.currentDailyToken!,
                        state.currentExhibition!),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32),
                ),
              ],
              // artwork desc
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: HtmlWidget(
                    customStylesBuilder: auHtmlStyle,
                    assetToken.description ?? '',
                    textStyle: theme.textTheme.ppMori400White14,
                    onTapUrl: (url) async {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                      return true;
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 64),
              ),

              // Daily note if not empty
              if (state.currentDailyToken?.dailyNote?.isNotEmpty ?? false) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ImportantNoteView(
                      title: 'daily_note'.tr(),
                      titleStyle: theme.textTheme.ppMori400White14,
                      note: state.currentDailyToken!.dailyNote!,
                      noteStyle: theme.textTheme.ppMori400White14,
                      backgroundColor: AppColor.auGreyBackground,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 64),
                ),
              ],

              // Artist Profile
              if (state.currentArtist != null) ...[
                SliverToBoxAdapter(
                  child: GestureDetector(
                      onTap: () {
                        unawaited(injector<NavigationService>()
                            .openFeralFileArtistPage(state.currentArtist!.id));
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child:
                            _shortArtistProfile(context, state.currentArtist!),
                      )),
                ),
                SliverToBoxAdapter(
                    child: addDivider(
                        height: 40,
                        color: AppColor.auQuickSilver,
                        thickness: 0.5)),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32),
                ),
              ],
              if (state.currentExhibition != null) ...[
                SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: () {
                      unawaited(Navigator.of(context).pushNamed(
                          AppRouter.exhibitionDetailPage,
                          arguments: ExhibitionDetailPayload(
                              exhibitions: [state.currentExhibition!],
                              index: 0)));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _exhibitionInfo(context, state.currentExhibition!),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                    child: addDivider(
                        height: 40,
                        color: AppColor.auQuickSilver,
                        thickness: 0.5)),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32),
                ),
              ],

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: artworkDetailsMetadataSection(
                    context,
                    assetToken,
                    artistName,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: artworkDetailsRightSection(
                    context,
                    assetToken,
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 100),
                  child: SizedBox(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _mediumDescription(BuildContext context, DailyToken currentDailyToken,
      Exhibition exhibition) {
    final theme = Theme.of(context);
    final seriesId = currentDailyToken.artwork?.seriesID;
    if (seriesId == null) {
      return const SizedBox();
    }

    final mediumDesc = exhibition.series
        ?.firstWhereOrNull((series) => series.id == seriesId)
        ?.metadata?['mediumDescription'] as List?;

    if (mediumDesc == null) {
      return const SizedBox();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: mediumDesc
          .map((desc) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  desc,
                  style: theme.textTheme.ppMori400White14,
                ),
              ))
          .toList(),
    );
  }

  Widget _shortArtistProfile(BuildContext context, FFUser artist) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'artist_profile'.tr(),
            style: Theme.of(context).textTheme.ppMori400Grey12,
          ),
          const SizedBox(height: 32),
          UserProfile(
            user: artist,
            isShowUserRole: false,
          ),
          const SizedBox(height: 32),
          Text(
            'read_more'.tr(),
            style: Theme.of(context).textTheme.ppMori400White14.copyWith(
                  decoration: TextDecoration.underline,
                ),
          ),
        ],
      );

  Widget _exhibitionInfo(BuildContext context, Exhibition exhibition) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'exhibited_in'.tr(),
          style: theme.textTheme.ppMori400Grey12,
        ),
        const SizedBox(height: 16),
        ExhibitionCard(
          exhibition: exhibition,
          viewableExhibitions: [exhibition],
          horizontalMargin: 16,
        ),
        const SizedBox(height: 48),
        HtmlWidget(
          exhibition.noteBrief,
          customStylesBuilder: auHtmlStyle,
          textStyle: theme.textTheme.ppMori400White14,
          onTapUrl: (url) async {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication);
            return true;
          },
        ),
        const SizedBox(height: 16),
        Text(
          'read_more'.tr(),
          style: theme.textTheme.ppMori400White14.copyWith(
            decoration: TextDecoration.underline,
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
