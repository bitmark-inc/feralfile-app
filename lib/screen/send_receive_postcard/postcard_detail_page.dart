//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/trip.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:share/share.dart';

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
  late Locale locale;
  late DistanceFormatter distanceFormatter;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    locale = Localizations.localeOf(context);
    distanceFormatter = DistanceFormatter(locale: locale);
    final theme = Theme.of(context);
    final asset = widget.asset;
    final artistName = asset.artistName?.toIdentityOrMask({});
    var subTitle = "";
    if (artistName != null && artistName.isNotEmpty) {
      subTitle = "by".tr(args: [artistName]);
    }
    final sendingTrip =
        Trip(from: 'Boulder, CO, USA', to: 'Unknown', distance: null);
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
                maxLines: 1,
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
                CachedNetworkImage(
                  imageUrl: asset.thumbnailURL ?? "",
                  fit: BoxFit.fitWidth,
                ),
                const SizedBox(height: 24.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "total_distance_traveled".tr(),
                      style: theme.textTheme.ppMori700White14,
                    ),
                    Text(
                      distanceFormatter.format(
                          distance: asset.totalDistanceTraveled),
                      style: theme.textTheme.ppMori700White14,
                    ),
                  ],
                ),

                addDivider(color: AppColor.greyMedium),
                if (asset.isSending) ...[
                  _sendingTripItem(
                      context,
                      Trip.sendingTrip(asset.trips.last.to),
                      asset.trips.length + 1),
                  addDivider(color: AppColor.greyMedium),
                ],
                ...asset.trips
                    .mapIndexed((index, el) => [
                          _tripItem(context, el, asset.trips.length - index),
                          addDivider(color: AppColor.greyMedium)
                        ])
                    .flattened
                    .toList(),
              ],
            ),
          ),
        ));
  }

  Widget _tripItem(BuildContext context, Trip el, int index) {
    final theme = Theme.of(context);
    NumberFormat formatter = NumberFormat("00");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatter.format(index),
          style: theme.textTheme.ppMori400Grey12,
        ),
        Text(
          el.from,
          style: theme.textTheme.ppMori400White14,
        ),
        Row(
          children: [
            SvgPicture.asset("assets/images/arrow_3.svg"),
            const SizedBox(width: 6),
            Text(
              el.to,
              style: theme.textTheme.ppMori400White14,
            ),
            const Spacer(),
            Text(
              distanceFormatter.format(distance: el.distance),
              style: theme.textTheme.ppMori400White14,
            )
          ],
        ),
      ],
    );
  }

  Widget _sendingTripItem(BuildContext context, Trip el, index) {
    final theme = Theme.of(context);
    NumberFormat formatter = NumberFormat("00");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatter.format(index),
          style: theme.textTheme.ppMori400Grey12,
        ),
        Row(
          children: [
            Text(
              el.from,
              style: theme.textTheme.ppMori400White14,
            ),
            const Spacer(),
            GestureDetector(
              child: Text("send_link_again".tr(),
                  style: theme.textTheme.ppMori400SupperTeal12),
              onTap: () {
                _sharePostcard(widget.asset);
              },
            )
          ],
        ),
        Row(
          children: [
            SvgPicture.asset("assets/images/arrow_3.svg"),
            const SizedBox(width: 6),
            Text(
              el.to,
              style: theme.textTheme.ppMori400White14,
            ),
            const Spacer(),
            Text(
              "waiting".tr(),
              style: theme.textTheme.ppMori400White14,
            )
          ],
        ),
      ],
    );
  }

  Future<void> _sharePostcard(AssetToken asset) async {
    final tezosService = injector<TezosService>();
    final owner = await asset.getOwnerWallet();
    final ownerWallet = owner?.first;
    final addressIndex = owner?.second;
    if (ownerWallet == null) {
      return;
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final message = Uint8List.fromList(utf8.encode(timestamp));
    final signature =
        await tezosService.signMessage(ownerWallet, addressIndex!, message);

    final sharePostcardRespone =
        await injector<PostcardService>().sharePostcard(asset, signature);
    if (sharePostcardRespone.url?.isNotEmpty ?? false) {
      Share.share(sharePostcardRespone.url!);
    }
  }
}
