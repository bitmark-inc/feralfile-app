import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_explain.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

class PostcardLocationExplain extends StatefulWidget {
  final PostcardExplainPayload payload;

  const PostcardLocationExplain({Key? key, required this.payload})
      : super(key: key);

  @override
  State<PostcardLocationExplain> createState() =>
      _PostcardLocationExplainState();
}

class _PostcardLocationExplainState extends State<PostcardLocationExplain> {
  final _navigationService = injector.get<NavigationService>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _locationExplain(context),
    ];
    final theme = Theme.of(context);
    final padding = ResponsiveLayout.pageHorizontalEdgeInsets;
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
        padding: const EdgeInsets.only(bottom: 32),
        child: Stack(
          children: [
            Swiper(
              onIndexChanged: (index) {},
              itemBuilder: (context, index) {
                return Padding(
                  padding: padding,
                  child: pages[index],
                );
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
    );
  }

  Widget _locationExplainItem(
      {required BuildContext context,
      required String imagePath,
      required String location,
      required double distance}) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Image.asset(imagePath),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    "assets/images/location_blue.svg",
                  ),
                  Text(
                    location,
                    style: theme.textTheme.moMASans400Black16
                        .copyWith(fontSize: 18),
                  ),
                ],
              ),
            ),
            Text(
              "plus_distance".tr(namedArgs: {
                "distance": DistanceFormatter().showDistance(
                    distance: distance, distanceUnit: DistanceUnit.mile),
              }),
              style: theme.textTheme.moMASans400Black16.copyWith(
                  fontSize: 18, color: const Color.fromRGBO(131, 79, 196, 1)),
            )
          ],
        ),
      ],
    );
  }

  Widget _locationExplain(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          Column(
            children: [
              _locationExplainItem(
                  context: context,
                  location: "Berlin, Germany",
                  distance: 3964,
                  imagePath: "assets/images/postcard_location_explain_1.png"),
              const SizedBox(height: 16),
              _locationExplainItem(
                  context: context,
                  location: "Paris, France",
                  distance: 545,
                  imagePath: "assets/images/postcard_location_explain_2.png"),
              const SizedBox(height: 16),
              _locationExplainItem(
                  context: context,
                  location: "Reykjavík, Iceland",
                  distance: 1340,
                  imagePath: "assets/images/postcard_location_explain_3.png"),
            ],
          ),
          const SizedBox(height: 60),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "your_location_is_used".tr(),
                      style: theme.textTheme.moMASans700Black14
                          .copyWith(fontSize: 18),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      _navigationService.showLocationExplain();
                    },
                    icon: const Icon(AuIcon.info),
                    padding: const EdgeInsets.all(0),
                    constraints: const BoxConstraints(
                      maxWidth: 24,
                      maxHeight: 24,
                    ),
                    iconSize: 24,
                  )
                ],
              ),
              const SizedBox(height: 38),
              Text(
                "enable_location_to_contribute".tr(),
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
