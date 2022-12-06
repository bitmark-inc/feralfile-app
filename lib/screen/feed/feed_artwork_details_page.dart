//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:collection';

import 'package:autonomy_flutter/model/feed.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/feed/feed_bloc.dart';
import 'package:autonomy_flutter/screen/gallery/gallery_page.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/au_outlined_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/provenance.dart';

class FeedArtworkDetailsPage extends StatefulWidget {
  const FeedArtworkDetailsPage({Key? key}) : super(key: key);

  @override
  State<FeedArtworkDetailsPage> createState() => _FeedArtworkDetailsPageState();
}

class _FeedArtworkDetailsPageState extends State<FeedArtworkDetailsPage> {
  late ScrollController _scrollController;
  late FeedEvent feedEvent;
  AssetToken? token;
  HashSet<String> _accountNumberHash = HashSet.identity();

  @override
  void initState() {
    _scrollController = ScrollController();
    fetchIdentities();
    super.initState();
  }

  void fetchIdentities() {
    final state = context.read<FeedBloc>().state;
    final currentIndex = state.viewingIndex ?? 0;
    final currentToken = state.feedTokens?[currentIndex];
    final currentFeedEvent = state.feedEvents?[currentIndex];

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

    return Stack(
      children: [
        Scaffold(
          appBar: getBackAppBar(
            context,
            backTitle: "discovery".tr(),
            onBack: () => Navigator.of(context).pop(),
          ),
          body: BlocBuilder<FeedBloc, FeedState>(builder: (context, state) {
            final currentIndex = state.viewingIndex ?? 0;
            final currentToken = state.feedTokens?[currentIndex];
            final currentFeedEvent = state.feedEvents?[currentIndex];
            if (currentFeedEvent == null || currentToken == null) {
              return const SizedBox();
            }

            feedEvent = currentFeedEvent;
            token = currentToken;

            final identityState = context.watch<IdentityBloc>().state;
            final followingName = feedEvent.recipient
                    .toIdentityOrMask(identityState.identityMap) ??
                feedEvent.recipient;
            final artistName =
                token?.artistName?.toIdentityOrMask(identityState.identityMap);
            final editionSubTitle = getEditionSubTitle(token!);

            return SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: ResponsiveLayout.getPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                                text: TextSpan(
                              style: ResponsiveLayout.isMobile
                                  ? theme.textTheme.atlasBlackBold12
                                  : theme.textTheme.atlasBlackBold14,
                              children: [
                                TextSpan(
                                  text: "_by".tr(
                                      args: [feedEvent.actionRepresentation]),
                                ),
                                TextSpan(
                                  text: followingName,
                                  style: ResponsiveLayout.isMobile
                                      ? theme.textTheme.atlasBlackBold12
                                      : theme.textTheme.atlasBlackBold14,
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.of(context)
                                        .pushNamed(AppRouter.galleryPage,
                                            arguments: GalleryPagePayload(
                                              address: feedEvent.recipient,
                                              artistName: followingName,
                                            )),
                                )
                              ],
                            )),
                            Text(
                              getDateTimeRepresentation(feedEvent.timestamp),
                              style: ResponsiveLayout.isMobile
                                  ? theme.textTheme.atlasBlackNormal12
                                  : theme.textTheme.atlasBlackNormal14,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          token!.title,
                          style: theme.textTheme.headline1,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            if (artistName?.isNotEmpty == true) ...[
                              Expanded(
                                  child: RichText(
                                      text: TextSpan(
                                          style: theme.textTheme.headline3,
                                          children: [
                                    TextSpan(text: "by".tr(args: [""])),
                                    if (token!.artistID != null) ...[
                                      TextSpan(
                                        text: artistName,
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () => Navigator.of(context)
                                              .pushNamed(AppRouter.galleryPage,
                                                  arguments: GalleryPagePayload(
                                                    address: token!.artistID!,
                                                    artistName: artistName!,
                                                    artistURL: token!.artistURL,
                                                  )),
                                        style: makeLinkStyle(
                                            theme.textTheme.headline3!),
                                      ),
                                    ] else ...[
                                      TextSpan(
                                        text: artistName,
                                      )
                                    ],
                                  ]))),
                            ] else ...[
                              const Expanded(child: SizedBox())
                            ],
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              editionSubTitle,
                              style: theme.textTheme.headline5?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                  GestureDetector(
                    child: TokenThumbnailWidget(
                      token: token!,
                    ),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  Padding(
                    padding: ResponsiveLayout.getPadding,
                    child: Text(
                      editionSubTitle,
                      style: theme.textTheme.ppMori400Grey12,
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
                                style: theme.textTheme.ppMori400Green12,
                                recognizer: TapGestureRecognizer()
                                  ..onTap =
                                      () => Navigator.of(context).pushNamed(
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
                        debugInfoWidget(context, token),
                        const SizedBox(height: 40.0),
                        HtmlWidget(
                          token?.desc ?? "",
                          textStyle: theme.textTheme.bodyText1,
                        ),
                        artworkDetailsRightSection(context, token!),
                        const SizedBox(height: 40.0),
                        artworkDetailsMetadataSection(
                            context, token!, artistName),
                        (token?.provenances ?? []).isNotEmpty
                            ? _provenanceView(context, token!.provenances!)
                            : const SizedBox(),
                        const SizedBox(height: 80.0),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ReportButton(
            token: token,
            scrollController: _scrollController,
          ),
        ),
      ],
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
