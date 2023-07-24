//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:nft_collection/models/asset_token.dart';

class ActivationTokenDetailPage extends StatefulWidget {
  final AssetToken assetToken;

  const ActivationTokenDetailPage({
    Key? key,
    required this.assetToken,
  }) : super(key: key);

  @override
  State<ActivationTokenDetailPage> createState() =>
      _ActivationTokenDetailPageState();
}

class _ActivationTokenDetailPageState extends State<ActivationTokenDetailPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assetToken = widget.assetToken;
    final artistName = assetToken.artistName ?? "";
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
                  assetToken.title ?? "",
                  style: theme.primaryTextTheme.displayLarge,
                ),
              ),
              const SizedBox(height: 8.0),
              Padding(
                padding: ResponsiveLayout.getPadding,
                child: Text(
                  "by".tr(args: [artistName]).trim(),
                  style: theme.primaryTextTheme.headlineMedium
                      ?.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 15.0),
              // Show artwork here.
              CachedNetworkImage(
                imageUrl: assetToken.getPreviewUrl() ?? "",
                fit: BoxFit.fitWidth,
              ),
              const SizedBox(height: 24.0),
              Padding(
                padding: ResponsiveLayout.getPadding,
                child: HtmlWidget(
                  customStylesBuilder: auHtmlStyle,
                  assetToken.description ?? '',
                  textStyle: theme.primaryTextTheme.bodyLarge,
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
                      child: artworkDetailsMetadataSection(
                        context,
                        widget.assetToken,
                        artistName,
                      ),
                    ),
                    const SizedBox(height: 40.0),
                    Theme(
                      data: theme.copyWith(textTheme: theme.primaryTextTheme),
                      child: artworkDetailsRightSection(
                        context,
                        widget.assetToken,
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
                    style: theme.primaryTextTheme.labelLarge,
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
