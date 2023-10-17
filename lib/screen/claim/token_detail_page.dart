//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/util/feralfile_extension.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class TokenDetailPage extends StatefulWidget {
  final FFSeries series;

  const TokenDetailPage({
    Key? key,
    required this.series,
  }) : super(key: key);

  @override
  State<TokenDetailPage> createState() => _TokenDetailPageState();
}

class _TokenDetailPageState extends State<TokenDetailPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final series = widget.series;
    final artist = series.artist;
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
                  series.title,
                  style: theme.primaryTextTheme.displayLarge,
                ),
              ),
              const SizedBox(height: 8.0),
              Padding(
                padding: ResponsiveLayout.getPadding,
                child: Text(
                  "by".tr(args: [artist?.getDisplayName() ?? ""]).trim(),
                  style: theme.primaryTextTheme.headlineMedium
                      ?.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 15.0),
              // Show artwork here.
              CachedNetworkImage(
                imageUrl: series.getThumbnailURL(),
                fit: BoxFit.fitWidth,
              ),
              const SizedBox(height: 24.0),
              Padding(
                padding: ResponsiveLayout.getPadding,
                child: HtmlWidget(
                  customStylesBuilder: auHtmlStyle,
                  series.description ?? '',
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
                      child: FeralfileArtworkDetailsMetadataSection(
                        series: widget.series,
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
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
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
