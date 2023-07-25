import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:video_player/video_player.dart';

class PostcardExplain extends StatefulWidget {
  static const String tag = 'postcard_explain_screen';
  final PostcardExplainPayload payload;

  const PostcardExplain({Key? key, required this.payload}) : super(key: key);

  @override
  State<PostcardExplain> createState() => _PostcardExplainState();
}

class _PostcardExplainState extends State<PostcardExplain> {
  bool _isLastPage = false;
  final VideoPlayerController _controller =
      VideoPlayerController.asset("assets/videos/postcard_explain.mp4");
  final VideoPlayerController _colouringController =
      VideoPlayerController.asset("assets/videos/colouring_video.mp4");

  @override
  void initState() {
    super.initState();
    injector<ConfigurationService>().setAutoShowPostcard(false);
    _colouringController.initialize().then((_) {
      _colouringController.setLooping(true);
      setState(() {});
      _colouringController.play();
    });
    _controller.initialize().then((_) {
      _controller.setLooping(true);
      setState(() {});
      _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _colouringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _page1(),
      _page3(1, _colouringController),
      _page2(2, totalDistance: 0),
      _page2(3, totalDistance: 7926),
      _page2(4, totalDistance: 91103),
      _page4(5)
    ];
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColor.chatPrimaryColor,
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColor.chatPrimaryColor,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "MoMA",
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.moMASans700Black24,
              textAlign: TextAlign.center,
            ),
            Text(
              "postcard_project".tr(),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.moMASans400Black24.copyWith(height: 1),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        toolbarHeight: 160,
        actions: [
          IconButton(
            tooltip: "CLOSE",
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            icon: closeIcon(),
          )
        ],
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
        child: Stack(
          children: [
            Swiper(
              onIndexChanged: (index) {
                setState(() {
                  _isLastPage = index == pages.length - 1;
                });
              },
              itemBuilder: (context, index) {
                return pages[index];
              },
              itemCount: pages.length,
              pagination: const SwiperPagination(
                  builder: DotSwiperPaginationBuilder(
                      color: AppColor.auLightGrey,
                      activeColor: MomaPallet.lightYellow)),
              control: const SwiperControl(
                  color: Colors.transparent,
                  disableColor: Colors.transparent,
                  size: 0),
              loop: false,
            ),
            Visibility(
              visible: _isLastPage,
              child: Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: widget.payload.startButton,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _page1() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
              height: 265,
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller))
                  : Container()),
          const SizedBox(height: 60),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "moma_project_invite".tr(),
                style: theme.textTheme.moMASans400Black14,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                      "game_runs_from_".tr(
                        namedArgs: {
                          "from": POSRCARD_GAME_START,
                          "to": POSRCARD_GAME_END,
                        },
                      ),
                      style: theme.textTheme.moMASans400Grey12
                          .copyWith(color: AppColor.auQuickSilver)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _page2(int index, {double? totalDistance}) {
    final imagePath = "assets/images/postcard_explain_$index.png";
    final theme = Theme.of(context);
    final distanceFormatter = DistanceFormatter();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 265,
            child: Center(
              child: Image.asset(
                imagePath,
                fit: BoxFit.fill,
              ),
            ),
          ),
          const SizedBox(height: 12),
          (totalDistance != null)
              ? Text(
                  "total_distance".tr(namedArgs: {
                    "distance": distanceFormatter.showDistance(
                        distance: totalDistance,
                        distanceUnit: DistanceUnit.mile)
                  }),
                  style: theme.textTheme.moMASans400Black14.copyWith(
                      fontSize: 18,
                      color: const Color.fromRGBO(131, 79, 196, 1)))
              : const SizedBox(height: 24),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$index.",
                style:
                    theme.textTheme.moMASans400Black14.copyWith(fontSize: 18),
              ),
              Text(
                "moma_explain_$index".tr(),
                style:
                    theme.textTheme.moMASans400Black14.copyWith(fontSize: 18),
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
                "$index.",
                style:
                    theme.textTheme.moMASans400Black14.copyWith(fontSize: 18),
              ),
              Text(
                "moma_explain_$index".tr(),
                style:
                    theme.textTheme.moMASans400Black14.copyWith(fontSize: 18),
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
            Text(title,
                style:
                    theme.textTheme.moMASans400Black14.copyWith(fontSize: 18)),
            Text(
                distanceFormatter.showDistance(
                    distance: totalDistance, distanceUnit: DistanceUnit.mile),
                style: theme.textTheme.moMASans400Black14.copyWith(
                    fontSize: 18,
                    color: const Color.fromRGBO(131, 79, 196, 1))),
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
                _rowItem(context, "1st".tr(), 91103,
                    "assets/images/postcard_leaderboard_1.svg"),
                const SizedBox(height: 35),
                _rowItem(context, "2nd".tr(), 88791,
                    "assets/images/postcard_leaderboard_2.svg"),
                const SizedBox(height: 35),
                _rowItem(context, "3rd".tr(), 64003,
                    "assets/images/postcard_leaderboard_3.svg"),
              ],
            ),
          ),
          const SizedBox(height: 60),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$index.",
                style:
                    theme.textTheme.moMASans400Black14.copyWith(fontSize: 18),
              ),
              Text(
                "moma_explain_$index".tr(),
                style:
                    theme.textTheme.moMASans400Black14.copyWith(fontSize: 18),
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

  PostcardExplainPayload(this.asset, this.startButton);
}
