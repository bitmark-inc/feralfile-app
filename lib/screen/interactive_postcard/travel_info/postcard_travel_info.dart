import 'package:autonomy_flutter/model/travel_infor.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_journey.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/moma_style_color.dart';
import 'package:autonomy_flutter/util/postcard_extension.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nft_collection/models/asset_token.dart';

class PostcardTravelInfo extends StatefulWidget {
  final AssetToken assetToken;
  final List<TravelInfo> listTravelInfo;
  final Function()? onCancelShare;

  const PostcardTravelInfo(
      {Key? key,
      required this.assetToken,
      required this.listTravelInfo,
      this.onCancelShare})
      : super(key: key);

  @override
  State<PostcardTravelInfo> createState() => _PostcardTravelInfoState();
}

class _PostcardTravelInfoState extends State<PostcardTravelInfo> {
  final distanceFormatter = DistanceFormatter();

  Widget _postcardProgress(
    AssetToken asset,
  ) {
    final theme = Theme.of(context);
    final travelInfoWithoutInternetUser =
        asset.postcardMetadata.listTravelInfoWithoutLocationName;
    final currentStampNumber = asset.getArtists.length;
    final numberFormatter = NumberFormat();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "total_distance_traveled".tr(),
          style: theme.textTheme.moMASans700Black16.copyWith(fontSize: 18),
        ),
        Text(
            distanceFormatter.format(
                distance: travelInfoWithoutInternetUser.totalDistance),
            style: theme.textTheme.moMASans400Black18
                .copyWith(color: MoMAColors.moMA12)),
        const SizedBox(height: 15),
        Row(
          children: [
            Text(
              "postcard_progress".tr(),
              style: theme.textTheme.moMASans400Grey12,
            ),
            const Spacer(),
            Text(
                "stamps_".tr(namedArgs: {
                  "current": numberFormatter.format(currentStampNumber),
                  "total": MAX_STAMP_IN_POSTCARD.toString(),
                }),
                style: theme.textTheme.moMASans400Grey12)
          ],
        ),
        Row(
          children: [
            ...List.generate(MAX_STAMP_IN_POSTCARD, (index) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: _progressItem(context, index, currentStampNumber),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _progressItem(
      BuildContext context, int index, int currentStampNumber) {
    final color =
        index < currentStampNumber ? MoMAColors.moMA12 : AppColor.auLightGrey;
    final borderRadius = index == 0
        ? const BorderRadius.only(
            topLeft: Radius.circular(50),
            bottomLeft: Radius.circular(50),
          )
        : index == MAX_STAMP_IN_POSTCARD - 1
            ? const BorderRadius.only(
                topRight: Radius.circular(50),
                bottomRight: Radius.circular(50),
              )
            : BorderRadius.zero;
    return Container(
      height: 13,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assetToken = widget.assetToken;
    final listTravelInfo = widget.listTravelInfo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _postcardProgress(assetToken),
        const SizedBox(
          height: 32,
        ),
        PostcardJourney(
          assetToken: assetToken,
          listTravelInfo: listTravelInfo,
          onCancelShare: () {
            widget.onCancelShare?.call();
          },
        )
      ],
    );
  }
}
