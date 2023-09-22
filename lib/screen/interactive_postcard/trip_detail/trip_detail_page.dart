import 'package:autonomy_flutter/model/travel_infor.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:autonomy_theme/style/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart';

class TripDetailPayload {
  final AssetToken assetToken;
  final int stampIndex;
  final List<TravelInfo> travelsInfo;
  String? imagePath;
  String? metadataPath;

  TripDetailPayload(
      {required this.assetToken,
      required this.stampIndex,
      required this.travelsInfo,
      this.metadataPath,
      this.imagePath});
}

class TripDetailPage extends StatefulWidget {
  final TripDetailPayload payload;

  const TripDetailPage({super.key, required this.payload});

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  final _distanceFormater = DistanceFormatter();
  late int _stampIndex;

  @override
  void initState() {
    super.initState();
    _stampIndex = widget.payload.stampIndex;
  }

  @override
  Widget build(BuildContext context) {
    final travelInfo = widget.payload.travelsInfo[_stampIndex];
    final theme = Theme.of(context);
    final tripName = "trip_".tr(namedArgs: {"index": "${_stampIndex + 1}"});
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      appBar: getBackAppBar(context, onBack: () {
        Navigator.of(context).pop();
      }, title: tripName, isWhite: false),
      body: Padding(
        padding: ResponsiveLayout.pageEdgeInsets,
        child: Column(
          children: [
            const SizedBox(
              height: 15,
            ),
            Stack(
              children: [
                AbsorbPointer(
                  child: AspectRatio(
                    aspectRatio: STAMP_ASPECT_RATIO,
                    child: PostcardViewWidget(
                      assetToken: widget.payload.assetToken,
                      zoomIndex: _stampIndex,
                    ),
                  ),
                ),
                Positioned.fill(child: Container()),
              ],
            ),
            addOnlyDivider(color: AppColor.auGreyBackground),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _distanceFormater.format(
                        distance: travelInfo.getDistance()),
                    style: theme.textTheme.moMASans700Black24
                        .copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            addOnlyDivider(color: AppColor.auGreyBackground),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        travelInfo.from.address ?? "",
                        style: theme.textTheme.moMASans400White14,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: SvgPicture.asset(
                      "assets/images/arrow_3.svg",
                      colorFilter: const ColorFilter.mode(
                          AppColor.white, BlendMode.srcIn),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        travelInfo.to.address ?? "",
                        style: theme.textTheme.moMASans400White14,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            addOnlyDivider(color: AppColor.auGreyBackground),
          ],
        ),
      ),
    );
  }
}
