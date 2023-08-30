//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/travel_infor.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/travel_info/travel_info_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/travel_info/travel_info_state.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/postcard_extension.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart';

class PostcardDetailPage extends StatefulWidget {
  final AssetToken asset;

  const PostcardDetailPage({
    Key? key,
    required this.asset,
  }) : super(key: key);

  @override
  State<PostcardDetailPage> createState() => _PostcardDetailPageState();
}

class _PostcardDetailPageState extends State<PostcardDetailPage> {
  late DistanceFormatter distanceFormatter;

  @override
  void initState() {
    super.initState();
    context.read<TravelInfoBloc>().add(GetTravelInfoEvent(asset: widget.asset));
  }

  @override
  Widget build(BuildContext context) {
    distanceFormatter = DistanceFormatter();
    final theme = Theme.of(context);
    final asset = widget.asset;
    final artistName = asset.artistName?.toIdentityOrMask({});
    var subTitle = "";
    if (artistName != null && artistName.isNotEmpty) {
      subTitle = "by".tr(args: [artistName]);
    }

    return Scaffold(
        appBar: AppBar(
          leadingWidth: 0,
          centerTitle: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                asset.title ?? '',
                style: theme.textTheme.ppMori400White16,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subTitle,
                style: theme.textTheme.ppMori400White14,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            Semantics(
              label: 'close_icon',
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                constraints: const BoxConstraints(
                  maxWidth: 44,
                  maxHeight: 44,
                ),
                icon: Icon(
                  AuIcon.close,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
              ),
            )
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                // Show artwork here.
                Center(
                  child: PostcardRatio(assetToken: widget.asset),
                ),
                const SizedBox(height: 24.0),
                travelInfoWidget(asset),
              ],
            ),
          ),
        ));
  }

  Widget travelInfoWidget(AssetToken asset) {
    final theme = Theme.of(context);
    return BlocConsumer<TravelInfoBloc, TravelInfoState>(
      listener: (context, state) {},
      builder: (context, state) {
        final travelInfo = state.listTravelInfo;
        final travelInfoWithoutInternet =
            asset.postcardMetadata.listTravelInfoWithoutLocationName;
        if (travelInfo == null) {
          return const SizedBox();
        }
        return Padding(
          padding: ResponsiveLayout.pageHorizontalEdgeInsets,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // travel distance row
              Row(
                children: [
                  Text(
                    "total_distance_traveled".tr(),
                    style: theme.textTheme.ppMori700White14,
                  ),
                  const Spacer(),
                  Text(
                    distanceFormatter.format(
                        distance: travelInfoWithoutInternet.totalDistance),
                    style: theme.textTheme.ppMori700White14,
                  ),
                ],
              ),
              addDivider(height: 30, color: AppColor.auGreyBackground),
              ...travelInfo
                  .mapIndexed((index, el) => [
                        _tripItem(context, el),
                        addDivider(color: AppColor.greyMedium)
                      ])
                  .flattened
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _tripItem(BuildContext context, TravelInfo travelInfo) {
    final theme = Theme.of(context);
    NumberFormat formatter = NumberFormat("00");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatter.format(travelInfo.index),
          style: theme.textTheme.ppMori400Grey12,
        ),
        Text(
          travelInfo.sentLocation ?? "Unknown",
          style: theme.textTheme.ppMori400White14,
        ),
        Row(
          children: [
            SvgPicture.asset("assets/images/arrow_3.svg"),
            const SizedBox(width: 6),
            Text(
              travelInfo.receivedLocation ?? "Unknown",
              style: theme.textTheme.ppMori400White14,
            ),
            const Spacer(),
            Text(
              distanceFormatter.format(distance: travelInfo.getDistance()),
              style: theme.textTheme.ppMori400White14,
            )
          ],
        ),
      ],
    );
  }
}
