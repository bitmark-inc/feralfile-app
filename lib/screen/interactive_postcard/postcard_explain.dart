import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/extensions/theme_extension/moma_sans.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:video_player/video_player.dart';

class PostcardExplain extends StatefulWidget {
  final PostcardExplainPayload payload;

  const PostcardExplain({required this.payload, super.key});

  @override
  State<PostcardExplain> createState() => _PostcardExplainState();
}

class _PostcardExplainState extends State<PostcardExplain> {
  final _navigationService = injector<NavigationService>();
  final VideoPlayerController _controller =
      VideoPlayerController.asset('assets/videos/postcard_explain.mp4');
  final VideoPlayerController _colouringController =
      VideoPlayerController.asset('assets/videos/colouring_video.mp4');
  late int _currentIndex;
  late SwiperController _swiperController;
  late bool _viewClaimPage;

  @override
  void initState() {
    _viewClaimPage = !widget.payload.isPayToMint;
    unawaited(_initColouringPlayer(!_viewClaimPage));
    if (_viewClaimPage) {
      unawaited(_initPlayer());
    }
    _swiperController = SwiperController();
    super.initState();
    unawaited(injector<ConfigurationService>().setAutoShowPostcard(false));
    _currentIndex = 0;
  }

  Future<void> _initPlayer() async {
    await _controller.initialize().then((_) {
      _controller.setLooping(true);
      setState(() {});
      _controller.play();
    });

    await _controller.play();
  }

  Future<void> _initColouringPlayer(bool doPlay) async {
    await _colouringController.initialize().then((_) {
      _colouringController.setLooping(true);
      if (doPlay) {
        setState(() {});
        _colouringController.play();
      }
    });
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    unawaited(_colouringController.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.payload.asset;
    final pages = widget.payload.pages ??
        [
          _page3(1, _colouringController),
          _page2(2, totalDistance: 0),
          _page2(3, totalDistance: 7926),
          _page2(4, totalDistance: 91103),
          _page4(5),
          if (asset.getArtists.isNotEmpty) _postcardPreview(context, asset),
        ];
    final swiperSize = pages.length;
    final theme = Theme.of(context);
    final padding = ResponsiveLayout.pageHorizontalEdgeInsets;
    final isLastPage = _currentIndex == pages.length - 1;
    return Scaffold(
      backgroundColor: AppColor.chatPrimaryColor,
      appBar: getLightEmptyAppBar(AppColor.chatPrimaryColor),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MoMA',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.moMASans700Black24
                            .copyWith(height: 1),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'postcard_project'.tr(),
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.moMASans400Black24
                            .copyWith(height: 1),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (!_viewClaimPage && !isLastPage) ...[
                    _skipButton(context, () async {
                      await _swiperController.move(swiperSize - 1);
                    })
                  ],
                ],
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: _viewClaimPage
                  ? Padding(
                      padding: padding,
                      child: _page1(_controller),
                    )
                  : Stack(
                      children: [
                        Swiper(
                          onIndexChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                              if (index == 0) {
                                unawaited(_colouringController.play());
                              }
                            });
                          },
                          itemBuilder: (context, index) => Padding(
                            padding: padding.copyWith(top: 40),
                            child: pages[index],
                          ),
                          itemCount: swiperSize,
                          pagination: const SwiperPagination(
                              builder: DotSwiperPaginationBuilder(
                                  color: AppColor.auLightGrey,
                                  activeColor: MomaPallet.lightYellow)),
                          control: const SwiperControl(
                              color: Colors.transparent,
                              disableColor: Colors.transparent,
                              size: 0),
                          loop: false,
                          controller: _swiperController,
                        ),
                        Visibility(
                          visible: isLastPage,
                          child: Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
                              padding: padding,
                              child: widget.payload.startButton,
                            ),
                          ),
                        )
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skipButton(BuildContext context, Function()? onSkip) =>
      GestureDetector(
        onTap: onSkip,
        child: Text(
          'skip'.tr(),
          style: Theme.of(context)
              .textTheme
              .moMASans400Grey14
              .copyWith(color: AppColor.auQuickSilver),
        ),
      );

  Widget _page1(VideoPlayerController controller) {
    final theme = Theme.of(context);
    final termsConditionsStyle = theme.textTheme.moMASans400Grey12.copyWith(
        color: AppColor.auQuickSilver, decorationColor: AppColor.auQuickSilver);
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
              height: 265,
              child: controller.value.isInitialized
                  ? VideoPlayer(controller)
                  : Container()),
          const SizedBox(height: 60),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'moma_project_invite'.tr(),
                style: theme.textTheme.moMASans400Black14,
              ),
              const SizedBox(height: 20),
              Text(
                'with_15_blank_stamps'.tr(),
                style: theme.textTheme.moMASans400Black14,
              ),
              const SizedBox(height: 40),
              Text.rich(
                textScaler: MediaQuery.textScalerOf(context),
                TextSpan(
                  style: termsConditionsStyle,
                  children: <TextSpan>[
                    TextSpan(
                      text: '${'by_continuing'.tr()} ',
                    ),
                    TextSpan(
                        text: 'terms_and_conditions'.tr(),
                        style: termsConditionsStyle.copyWith(
                            decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            unawaited(_navigationService.openAutonomyDocument(
                                MOMA_TERMS_CONDITIONS_URL,
                                'terms_and_conditions'.tr()));
                          }),
                    const TextSpan(
                      text: '.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              PostcardButton(
                text: 'claim_postcard'.tr(),
                onTap: () {
                  setState(() {
                    _viewClaimPage = false;
                  });
                  Future.delayed(const Duration(milliseconds: 50), () {
                    unawaited(_colouringController.play());
                  });
                },
              ),
              const SizedBox(height: 10),
              PostcardButton(
                text: 'decline_postcard'.tr(),
                color: AppColor.secondarySpanishGrey,
                onTap: () {
                  Navigator.of(context).pop(false);
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _page2(int index, {double? totalDistance}) {
    final imagePath = 'assets/images/postcard_explain_$index.png';
    final theme = Theme.of(context);
    final distanceFormatter = DistanceFormatter();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (totalDistance != null)
            Text(
                'total_distance'.tr(namedArgs: {
                  'distance': distanceFormatter.showDistance(
                      distance: totalDistance, distanceUnit: DistanceUnit.mile)
                }),
                style: theme.textTheme.moMASans400Black18
                    .copyWith(color: const Color.fromRGBO(131, 79, 196, 1)))
          else
            const SizedBox(height: 24),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'moma_explain_$index'.tr(),
                style: theme.textTheme.moMASans400Black18,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _page3(int index, VideoPlayerController controller) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
                height: 265,
                child: controller.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: VideoPlayer(controller))
                    : Container()),
          ),
          const SizedBox(height: 60),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'moma_explain_$index'.tr(),
                style: theme.textTheme.moMASans400Black18,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _rowItem(BuildContext context, String title, double totalDistance,
      String imagePath) {
    final theme = Theme.of(context);
    final distanceFormatter = DistanceFormatter();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          imagePath,
          height: 65,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.moMASans400Black18),
            Text(
                distanceFormatter.showDistance(
                    distance: totalDistance, distanceUnit: DistanceUnit.mile),
                style: theme.textTheme.moMASans400Black18
                    .copyWith(color: const Color.fromRGBO(131, 79, 196, 1))),
          ],
        )
      ],
    );
  }

  Widget _page4(int index) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 265,
            child: Column(
              children: [
                _rowItem(context, '1st'.tr(), 91103,
                    'assets/images/postcard_leaderboard_1.svg'),
                const SizedBox(height: 35),
                _rowItem(context, '2nd'.tr(), 88791,
                    'assets/images/postcard_leaderboard_2.svg'),
                const SizedBox(height: 35),
                _rowItem(context, '3rd'.tr(), 64003,
                    'assets/images/postcard_leaderboard_3.svg'),
              ],
            ),
          ),
          const SizedBox(height: 60),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'moma_explain_$index'.tr(),
                style: theme.textTheme.moMASans400Black18,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _postcardPreview(BuildContext context, AssetToken asset) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 30,
                  height: (MediaQuery.of(context).size.width - 30) /
                      postcardAspectRatio,
                  child: PostcardViewWidget(
                    assetToken: asset,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'this_is_your_group_postcard'.tr(),
                style: theme.textTheme.moMASans400Black18,
              ),
            ],
          )
        ],
      ),
    );
  }
}

class PostcardExplainPayload {
  final AssetToken asset;
  final Widget startButton;
  final bool isPayToMint;
  final List<Widget>? pages;

  PostcardExplainPayload(this.asset, this.startButton,
      {this.isPayToMint = false, this.pages});
}
