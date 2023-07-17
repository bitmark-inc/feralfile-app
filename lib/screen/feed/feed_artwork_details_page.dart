//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:collection';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/feed.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/feed/feed_preview_page.dart';
import 'package:autonomy_flutter/screen/gallery/gallery_page.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/provenance.dart';

import '../../util/style.dart';

class FeedArtworkDetailsPage extends StatefulWidget {
  final FeedDetailPayload payload;

  const FeedArtworkDetailsPage({Key? key, required this.payload})
      : super(key: key);

  @override
  State<FeedArtworkDetailsPage> createState() => _FeedArtworkDetailsPageState();
}

class _FeedArtworkDetailsPageState extends State<FeedArtworkDetailsPage>
    with AfterLayoutMixin<FeedArtworkDetailsPage> {
  late ScrollController _scrollController;
  late List<FeedEvent> feedEvents;
  AssetToken? assetToken;
  HashSet<String> _accountNumberHash = HashSet.identity();
  final _metricClient = injector<MetricClientService>();

  @override
  void initState() {
    _scrollController = ScrollController();
    fetchIdentities();
    super.initState();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _metricClient.addEvent(MixpanelEvent.viewDiscoveryArtwork, data: {
      "id": widget.payload.feedToken?.id,
      "eventId": widget.payload.feedEvents.first.id,
      "action": widget.payload.feedEvents.first.action
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void fetchIdentities() {
    final currentToken = widget.payload.feedToken;
    final currentFeedEvents = widget.payload.feedEvents;

    final neededIdentities = [
      currentToken?.artistName ?? '',
      ...currentFeedEvents.map((e) => e.recipient),
    ];
    neededIdentities.removeWhere((element) => element == '');

    if (neededIdentities.isNotEmpty) {
      context.read<IdentityBloc>().add(GetIdentityEvent(neededIdentities));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentToken = widget.payload.feedToken;
    final currentFeedEvents = widget.payload.feedEvents;
    if (currentFeedEvents.isEmpty || currentToken == null) {
      return const SizedBox();
    }
    feedEvents = currentFeedEvents;
    assetToken = currentToken;

    final identityState = context.watch<IdentityBloc>().state;
    final artistName =
        assetToken?.artistName?.toIdentityOrMask(identityState.identityMap);
    final editionSubTitle = getEditionSubTitle(assetToken!);
    var subTitle = "";
    if (artistName != null && artistName.isNotEmpty) {
      subTitle = artistName;
    }

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 0,
        centerTitle: false,
        title: ArtworkDetailsHeader(
          title: assetToken?.title ?? '',
          subTitle: subTitle,
          onTitleTap: () {
            Navigator.of(context).pushNamed(AppRouter.irlWebView,
                arguments: assetToken?.secondaryMarketURL ?? '');
          },
          onSubTitleTap: assetToken!.artistID != null
              ? () => Navigator.of(context).pushNamed(AppRouter.galleryPage,
                  arguments: GalleryPagePayload(
                    address: assetToken!.artistID!,
                    artistName: artistName!,
                    artistURL: assetToken!.artistURL,
                  ))
              : null,
        ),
        actions: [
          IconButton(
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
            tooltip: 'close_icon',
          )
        ],
      ),
      backgroundColor: theme.colorScheme.primary,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 40,
                ),
                GestureDetector(
                  child: Center(
                    child: FeedArtwork(
                      assetToken: assetToken,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(
                  height: 40,
                ),
                Visibility(
                  visible: editionSubTitle.isNotEmpty,
                  child: Padding(
                    padding: ResponsiveLayout.getPadding,
                    child: Text(
                      editionSubTitle,
                      style: theme.textTheme.ppMori400Grey14,
                    ),
                  ),
                ),
                Padding(
                  padding: ResponsiveLayout.getPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      debugInfoWidget(context, assetToken),
                      const SizedBox(height: 40.0),
                      HtmlWidget(
                        customStylesBuilder: auHtmlStyle,
                        assetToken?.description ?? "",
                        textStyle: theme.textTheme.ppMori400White14,
                      ),
                      const SizedBox(height: 40.0),
                      artworkDetailsMetadataSection(
                          context, assetToken!, artistName),
                      (assetToken?.provenance ?? []).isNotEmpty
                          ? _provenanceView(context, assetToken!.provenance)
                          : const SizedBox(),
                      artworkDetailsRightSection(context, assetToken!),
                      const SizedBox(height: 80.0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _provenanceView(BuildContext context, List<Provenance> provenances) {
    return BlocBuilder<IdentityBloc, IdentityState>(
      builder: (context, identityState) =>
          BlocBuilder<AccountsBloc, AccountsState>(
              builder: (context, accountsState) {
        final event = accountsState.event;
        if (event != null && event is FetchAllAddressesSuccessEvent) {
          _accountNumberHash = HashSet.of(event.addresses);
        }

        return artworkDetailsProvenanceSectionNotEmpty(context, provenances,
            _accountNumberHash, identityState.identityMap);
      }),
    );
  }
}
