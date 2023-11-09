import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/postcard_metadata.dart';
import 'package:autonomy_flutter/model/travel_infor.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/geolocation.dart';
import 'package:autonomy_flutter/util/moma_style_color.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart';

class PostcardJourney extends StatefulWidget {
  final AssetToken assetToken;
  final List<TravelInfo> listTravelInfo;

  const PostcardJourney({
    super.key,
    required this.assetToken,
    required this.listTravelInfo,
  });

  @override
  State<PostcardJourney> createState() => _PostcardJourneyState();
}

class _PostcardJourneyState extends State<PostcardJourney> {
  final numberFormatter = NumberFormat("00");
  final distanceFormatter = DistanceFormatter();
  final _postcardService = injector.get<PostcardService>();
  final _configurationService = injector.get<ConfigurationService>();
  late bool isSending;

  @override
  void initState() {
    isSending = widget.assetToken.isSending;
    super.initState();
  }

  Widget _locationAddress(BuildContext context,
      {required int index, required String address, Color? overrideColor}) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          numberFormatter.format(index),
          style: theme.textTheme.moMASans400Black12.copyWith(
            color: overrideColor ?? AppColor.auQuickSilver,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          address,
          style:
              theme.textTheme.moMASans400Black12.copyWith(color: overrideColor),
        ),
      ],
    );
  }

  Widget _travelWidget(TravelInfo travelInfo, {Color? overrideColor}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _arrowLine(
          context,
          arrow: _postcardJourneyArrow(context),
          child: Text(
            distanceFormatter.format(
                distance: travelInfo.getDistance(), prefix: "+"),
            style: theme.textTheme.moMASans400Black12.copyWith(
              color: overrideColor ?? MoMAColors.moMA12,
              fontSize: 10,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: _locationAddress(context,
              address: travelInfo.to.address ?? "",
              index: travelInfo.index + 1),
        ),
      ],
    );
  }

  Widget _webTravelWidget(TravelInfo travelInfo,
      {Function()? onTap, Widget? arrow}) {
    const overrideColor = AppColor.auQuickSilver;
    final defaultArrow = _postcardWebUserArrow(context);
    return _arrowLine(context,
        arrow: arrow ?? defaultArrow,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: _locationAddress(
            context,
            index: travelInfo.index + 1,
            address: travelInfo.to.address ?? "",
            overrideColor: overrideColor,
          ),
        ),
        onTap: onTap);
  }

  Widget _postcardJourneyArrow(BuildContext context) {
    return SizedBox(
      width: 9.5,
      child: Align(
        alignment: Alignment.topRight,
        child: SvgPicture.asset(
          "assets/images/arrow-50-head.svg",
          fit: BoxFit.fitHeight,
          height: 50,
          width: 9,
        ),
      ),
    );
  }

  Widget _postcardWebUserArrowWithHead(BuildContext context) {
    return SizedBox(
      width: 9.5,
      child: Align(
        alignment: Alignment.topRight,
        child: SvgPicture.asset(
          "assets/images/arrow-80-head.svg",
          fit: BoxFit.fitHeight,
          height: 80,
          width: 9,
        ),
      ),
    );
  }

  Widget _postcardWebUserArrow(BuildContext context) {
    return SizedBox(
      width: 9,
      child: Align(
        alignment: Alignment.topCenter,
        child: SvgPicture.asset(
          "assets/images/arrow-80.svg",
          fit: BoxFit.fitHeight,
          height: 80,
        ),
      ),
    );
  }

  Widget _sendingTripItem(BuildContext context, AssetToken asset, int index) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _postcardJourneyArrow(context),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _locationAddress(
                context,
                address: "waiting_for_recipient".tr(),
                index: index + 1,
                overrideColor: AppColor.auQuickSilver,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _arrowLine(BuildContext context,
      {required Widget arrow, required Widget child, Function()? onTap}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 12, child: Center(child: arrow)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onTap,
              child: child,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.assetToken;
    final travelInfo = widget.listTravelInfo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _locationAddress(
            context,
            address: 'postcard_starting_location'
                .tr(namedArgs: {'location': moMAGeoLocation.address!}),
            index: 1,
          ),
        ),
        ...travelInfo
            .mapIndexed((int index, TravelInfo e) {
              List<TravelInfo> travelInfoOnTripDetail = travelInfo.toList();
              if (index + 1 > travelInfo.length - 1) {
                travelInfoOnTripDetail.add(TravelInfo(
                    e.to,
                    GeoLocation(
                        position: Location(lat: null, lon: null), address: ""),
                    e.index + 1));
              }
              if (e.to.isInternet) {
                final arrow = e.index == travelInfo.length &&
                        !(asset.isSending && asset.isLastOwner)
                    ? _postcardWebUserArrowWithHead(context)
                    : _postcardWebUserArrow(context);
                return [
                  _webTravelWidget(e, arrow: arrow),
                ];
              }
              return [
                _travelWidget(e),
              ];
            })
            .flattened
            .toList(),
        if (asset.isSending && asset.isLastOwner)
          _sendingTripItem(context, asset, travelInfo.length + 1)
      ],
    );
  }
}
