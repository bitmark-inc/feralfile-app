//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/editorial.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/screen/editorial/common/bottom_link.dart';
import 'package:autonomy_flutter/screen/editorial/common/publisher_view.dart';
import 'package:autonomy_flutter/screen/editorial/feralfile/exhibition_bloc.dart';
import 'package:autonomy_flutter/screen/editorial/feralfile/exhibition_state.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class ExhibitionView extends StatefulWidget {
  final String id;
  final Publisher publisher;
  final String tag;

  const ExhibitionView(
      {Key? key, required this.id, required this.publisher, required this.tag})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ExhibitionViewState();
}

class _ExhibitionViewState extends State<ExhibitionView> {
  @override
  void initState() {
    super.initState();

    context.read<ExhibitionBloc>().add(GetExhibitionEvent(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExhibitionBloc, ExhibitionState>(
        builder: (context, state) {
      final exhibition = state.exhibition;
      final theme = Theme.of(context);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: ResponsiveLayout.pageHorizontalEdgeInsets,
            child: PublisherView(publisher: widget.publisher),
          ),
          const SizedBox(height: 10.0),
          Padding(
            padding: ResponsiveLayout.pageHorizontalEdgeInsets,
            child: Text(
              exhibition?.title ?? "",
              style: theme.textTheme.ppMori400White14,
            ),
          ),
          const SizedBox(height: 15.0),
          SizedBox(
            height: 350,
            child: _ffArtworks(context, exhibition),
          ),
          Padding(
            padding: ResponsiveLayout.pageHorizontalEdgeInsets,
            child: BottomLink(
              name: "visit".tr(),
              tag: widget.tag,
              onTap: () {
                if (exhibition == null) return;
                launchUrl(
                  Uri.parse(feralFileExhibitionUrl(exhibition.slug)),
                  mode: LaunchMode.externalApplication,
                );
                final metricClient = injector<MetricClientService>();
                metricClient.addEvent(
                  MixpanelEvent.visitExhibition,
                  data: {'id': exhibition.id},
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _ffArtworks(BuildContext context, Exhibition? exhibition) {
    if (exhibition?.series == null) return const SizedBox();

    final theme = Theme.of(context);
    final artworks = exhibition!.series!;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: artworks.length,
      itemBuilder: (BuildContext context, int index) {
        final artwork = artworks[index];

        return GestureDetector(
          onTap: () {
            launchUrl(
              Uri.parse(feralFileArtworkUrl(artwork.slug)),
              mode: LaunchMode.externalApplication,
            );
            final metricClient = injector<MetricClientService>();
            metricClient.addEvent(MixpanelEvent.visitExhibitionArtwork,
                data: {'id': artwork.id, 'exhibition': exhibition.id});
          },
          child: Container(
            margin: EdgeInsets.only(
              left: index == 0 ? 15.0 : 0.0,
              right: ResponsiveLayout.padding,
            ),
            width: 285,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CachedNetworkImage(
                  fit: BoxFit.cover,
                  imageUrl: artwork.getThumbnailURL(),
                  width: 285,
                  height: 285,
                ),
                const SizedBox(height: 15.0),
                Text(
                  artwork.title,
                  style: theme.textTheme.ppMori400White14,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "by".tr(args: [artwork.artist?.fullName ?? ""]),
                  style: theme.textTheme.ppMori400White12,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
