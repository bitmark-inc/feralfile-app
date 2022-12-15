//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/util/feralfile_extension.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class TokenDetailPage extends StatefulWidget {
  final FFArtwork artwork;

  const TokenDetailPage({
    Key? key,
    required this.artwork,
  }) : super(key: key);

  @override
  State<TokenDetailPage> createState() => _TokenDetailPageState();
}

class _TokenDetailPageState extends State<TokenDetailPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artwork = widget.artwork;
    final contract = artwork.contract;
    final artist = artwork.artist;
    return Scaffold(
        appBar: _appBar(
          context,
          onBack: () => Navigator.of(context).pop(),
        ),
        backgroundColor: theme.colorScheme.primary,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16.0),
              Padding(
                padding: ResponsiveLayout.getPadding,
                child: Text(
                  artwork.title,
                  style: theme.primaryTextTheme.headline1,
                ),
              ),
              const SizedBox(height: 8.0),
              Padding(
                padding: ResponsiveLayout.getPadding,
                child: Text(
                  "by".tr(args: [artist.getDisplayName()]).trim(),
                  style:
                      theme.primaryTextTheme.headline4?.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 15.0),
              // Show artwork here.
              CachedNetworkImage(
                imageUrl: artwork.getThumbnailURL(),
                fit: BoxFit.fitWidth,
              ),
              const SizedBox(height: 24.0),
              Padding(
                padding: ResponsiveLayout.getPadding,
                child: HtmlWidget(
                  artwork.description,
                  textStyle: theme.primaryTextTheme.bodyText1,
                ),
              ),
              const SizedBox(height: 40.0),
              Padding(
                padding: ResponsiveLayout.getPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Theme(
                      data: theme.copyWith(textTheme: theme.primaryTextTheme),
                      child: FeralfileArtworkDetailsMetadataSection(
                        artwork: widget.artwork,
                      ),
                    ),
                    const SizedBox(height: 40.0),
                    Theme(
                      data: theme.copyWith(textTheme: theme.primaryTextTheme),
                      child: ArtworkRightWidget(
                        contract: contract,
                        exhibitionID: widget.artwork.exhibition?.id,
                      ),
                    ),
                    const SizedBox(height: 40.0),
                  ],
                ),
              )
            ],
          ),
        ));
  }

  AppBar _appBar(
    BuildContext context, {
    required void Function() onBack,
  }) {
    final theme = Theme.of(context);
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: theme.colorScheme.secondary,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      leading: const SizedBox(),
      leadingWidth: 0.0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 7, 18, 8),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/nav-arrow-left.svg',
                    color: Colors.white,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    "BACK",
                    style: theme.primaryTextTheme.button,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
    );
  }
}
