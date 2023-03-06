//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:collection';

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
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/provenance.dart';

class FeedArtworkDetailsPage extends StatefulWidget {
  final FeedDetailPayload payload;

  const FeedArtworkDetailsPage({Key? key, required this.payload})
      : super(key: key);

  @override
  State<FeedArtworkDetailsPage> createState() => _FeedArtworkDetailsPageState();
}

class _FeedArtworkDetailsPageState extends State<FeedArtworkDetailsPage> {
  late ScrollController _scrollController;
  late FeedEvent feedEvent;
  AssetToken? assetToken;
  HashSet<String> _accountNumberHash = HashSet.identity();

  @override
  void initState() {
    _scrollController = ScrollController();
    injector<MetricClientService>()
        .addEvent(MixpanelEvent.viewDiscoveryArtwork, data: {
      "id": widget.payload.feedToken?.id,
      "eventId": widget.payload.feedEvent?.id,
      "action": widget.payload.feedEvent?.action
    });
    fetchIdentities();
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void fetchIdentities() {
    final currentToken = widget.payload.feedToken;
    final currentFeedEvent = widget.payload.feedEvent;

    final neededIdentities = [
      currentToken?.artistName ?? '',
      currentFeedEvent?.recipient ?? ''
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
    final currentFeedEvent = widget.payload.feedEvent;
    if (currentFeedEvent == null || currentToken == null) {
      return const SizedBox();
    }

    feedEvent = currentFeedEvent;
    assetToken = currentToken;

    final identityState = context.watch<IdentityBloc>().state;
    final followingName =
        feedEvent.recipient.toIdentityOrMask(identityState.identityMap) ??
            feedEvent.recipient;
    final artistName =
        assetToken?.artistName?.toIdentityOrMask(identityState.identityMap);
    final editionSubTitle = getEditionSubTitle(assetToken!);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assetToken?.title ?? '',
              style: theme.textTheme.ppMori400White14,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (artistName?.isNotEmpty == true) ...[
              RichText(
                text: TextSpan(
                  style: theme.textTheme.ppMori400White12,
                  children: [
                    TextSpan(text: "by".tr(args: [""])),
                    TextSpan(
                      text: artistName,
                      recognizer: TapGestureRecognizer()
                        ..onTap = assetToken!.artistID != null
                            ? () => Navigator.of(context)
                                .pushNamed(AppRouter.galleryPage,
                                    arguments: GalleryPagePayload(
                                      address: assetToken!.artistID!,
                                      artistName: artistName!,
                                      artistURL: assetToken!.artistURL,
                                    ))
                            : null,
                      style: theme.textTheme.ppMori400White12,
                    ),
                  ],
                ),
              ),
            ],
          ],
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
                      style: theme.textTheme.ppMori400Grey12,
                    ),
                  ),
                ),
                Padding(
                  padding: ResponsiveLayout.getPadding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: ResponsiveLayout.isMobile
                              ? theme.textTheme.ppMori400White12
                              : theme.textTheme.ppMori400White14,
                          children: [
                            TextSpan(
                              text: "_by"
                                  .tr(args: [feedEvent.actionRepresentation]),
                            ),
                            TextSpan(
                              text: followingName,
                              style: theme.textTheme.ppMori400SupperTeal12,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => Navigator.of(context).pushNamed(
                                      AppRouter.galleryPage,
                                      arguments: GalleryPagePayload(
                                        address: feedEvent.recipient,
                                        artistName: followingName,
                                      ),
                                    ),
                            )
                          ],
                        ),
                      ),
                    ],
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
                        assetToken?.description ?? "",
                        textStyle: theme.textTheme.ppMori400White12,
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ReportButton(
              assetToken: assetToken,
              scrollController: _scrollController,
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
