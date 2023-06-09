import 'package:autonomy_flutter/model/travel_infor.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:autonomy_theme/style/colors.dart';
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
    final tripName = "Trip $_stampIndex";
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
            AspectRatio(
              aspectRatio: 1,
              child: PostcardViewWidget(
                assetToken: widget.payload.assetToken,
                zoomIndex: travelInfo.index,
              ),
            ),
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
            addOnlyDivider(color: Colors.white),
            const SizedBox(
              height: 22,
            ),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      travelInfo.sentLocation ?? "",
                      style: theme.textTheme.moMASans400White14,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  "assets/images/arrow_3.svg",
                  color: AppColor.white,
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      travelInfo.receivedLocation ?? "",
                      style: theme.textTheme.moMASans400White14,
                    ),
                  ),
                ),
              ],
            )
            // _tripInfo(travelInfo);
          ],
        ),
      ),
    );
  }
}
