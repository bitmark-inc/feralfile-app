import 'dart:collection';

import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/model/feed.dart';
import 'package:autonomy_flutter/model/provenance.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/feed/feed_bloc.dart';
import 'package:autonomy_flutter/screen/gallery/gallery_page.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/au_outlined_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:html_unescape/html_unescape.dart';

import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';

class FeedArtworkDetailsPage extends StatefulWidget {
  const FeedArtworkDetailsPage({Key? key}) : super(key: key);

  @override
  State<FeedArtworkDetailsPage> createState() => _FeedArtworkDetailsPageState();
}

class _FeedArtworkDetailsPageState extends State<FeedArtworkDetailsPage> {
  late ScrollController _scrollController;
  bool _showArtwortReportProblemContainer = true;
  late FeedEvent feedEvent;
  AssetToken? token;
  HashSet<String> _accountNumberHash = HashSet.identity();

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    super.initState();
  }

  _scrollListener() {
    /*
    So we see it like that when we are at the top of the page. 
    When we start scrolling down it disappears and we see it again attached at the bottom of the page.
    And if we scroll all the way up again, we would display again it attached down the screen
    https://www.figma.com/file/Ze71GH9ZmZlJwtPjeHYZpc?node-id=51:5175#159199971
    */
    if (_scrollController.offset > 80) {
      setState(() {
        _showArtwortReportProblemContainer = false;
      });
    } else {
      setState(() {
        _showArtwortReportProblemContainer = true;
      });
    }

    if (_scrollController.position.pixels + 100 >=
        _scrollController.position.maxScrollExtent) {
      setState(() {
        _showArtwortReportProblemContainer = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final unescape = HtmlUnescape();

    return Stack(
      fit: StackFit.loose,
      children: [
        Scaffold(
          appBar: getBackAppBar(
            context,
            backTitle: "DISCOVERY",
            onBack: () => Navigator.of(context).pop(),
          ),
          body: BlocConsumer<FeedBloc, FeedState>(listener: (context, state) {
            if (state.viewingToken?.artistName == null) return;
            final neededIdentities = [
              state.viewingToken?.artistName ?? '',
              state.viewingFeedEvent?.recipient ?? ''
            ];
            neededIdentities.removeWhere((element) => element == '');

            if (neededIdentities.isNotEmpty) {
              context
                  .read<IdentityBloc>()
                  .add(GetIdentityEvent(neededIdentities));
            }
          }, builder: (context, state) {
            if (state.viewingFeedEvent == null || state.viewingToken == null)
              return SizedBox();

            feedEvent = state.viewingFeedEvent!;
            token = state.viewingToken!;

            final identityState = context.watch<IdentityBloc>().state;
            final followingName = feedEvent.recipient
                    .toIdentityOrMask(identityState.identityMap) ??
                feedEvent.recipient;
            final artistName =
                token?.artistName?.toIdentityOrMask(identityState.identityMap);
            final editionSubTitle = getEditionSubTitle(token!);

            final theme = AuThemeManager.get(AppTheme.previewNFTTheme);

            return Container(
                child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                                text: TextSpan(
                              style: appTextTheme.headline4
                                  ?.copyWith(fontSize: 12),
                              children: [
                                TextSpan(
                                  text: feedEvent.actionRepresentation + ' by ',
                                ),
                                TextSpan(
                                  text: followingName,
                                  style: makeLinkStyle(appTextTheme.headline4!
                                      .copyWith(fontSize: 12)),
                                  recognizer: new TapGestureRecognizer()
                                    ..onTap = () => Navigator.of(context)
                                        .pushNamed(AppRouter.galleryPage,
                                            arguments: GalleryPagePayload(
                                              address: feedEvent.recipient,
                                              artistName: followingName,
                                              artistURL: null,
                                            )),
                                )
                              ],
                            )),
                            Text(getDateTimeRepresentation(feedEvent.timestamp),
                                style: labelSmall),
                          ],
                        ),
                        SizedBox(height: 2.0),
                        Text(
                          token!.title,
                          style: appTextTheme.headline1,
                        ),
                        if (artistName != null && artistName.isNotEmpty) ...[
                          SizedBox(height: 4),
                          RichText(
                              text: TextSpan(
                                  style: appTextTheme.headline3,
                                  children: [
                                TextSpan(text: "by "),
                                if (token!.artistID != null) ...[
                                  TextSpan(
                                    text: artistName,
                                    recognizer: new TapGestureRecognizer()
                                      ..onTap = () => Navigator.of(context)
                                          .pushNamed(AppRouter.galleryPage,
                                              arguments: GalleryPagePayload(
                                                address: token!.artistID!,
                                                artistName: artistName,
                                                artistURL: token!.artistURL,
                                              )),
                                    style:
                                        makeLinkStyle(appTextTheme.headline3!),
                                  ),
                                ] else ...[
                                  TextSpan(
                                    text: artistName,
                                  )
                                ],
                                if (editionSubTitle.isNotEmpty) ...[
                                  TextSpan(text: editionSubTitle)
                                ]
                              ]))
                        ],
                        SizedBox(height: 15),
                      ],
                    ),
                  ),
                  GestureDetector(
                    child: tokenThumbnailWidget(context, token!),
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRouter.feedArtworkDetailsPage),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        debugInfoWidget(token),
                        SizedBox(height: 16.0),
                        Container(
                          width: 165,
                          height: 48,
                          child: AuOutlinedButton(
                            text: "VIEW ARTWORK",
                            onPress: () => Navigator.of(context)
                                .pushNamed(AppRouter.feedPreviewPage),
                          ),
                        ),
                        SizedBox(height: 40.0),
                        Text(
                          unescape.convert(token?.desc ?? ""),
                          style: appTextTheme.bodyText1,
                        ),
                        artworkDetailsRightSection(context, token!),
                        SizedBox(height: 40.0),
                        artworkDetailsMetadataSection(
                            context, token!, artistName),
                        (token?.provenances ?? []).isNotEmpty
                            ? _provenanceView(context, token!.provenances!)
                            : SizedBox(),
                        SizedBox(height: 80.0),
                      ],
                    ),
                  ),
                ],
              ),
            ));
          }),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: reportNFTProblemContainer(
              token, _showArtwortReportProblemContainer),
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
