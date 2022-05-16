import 'dart:collection';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/model/asset_price.dart';
import 'package:autonomy_flutter/model/provenance.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_state.dart';
import 'package:autonomy_flutter/screen/detail/report_rendering_issue_widget.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/au_cached_manager.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_outlined_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

class ArtworkDetailPage extends StatefulWidget {
  final ArtworkDetailPayload payload;

  const ArtworkDetailPage({Key? key, required this.payload}) : super(key: key);

  @override
  State<ArtworkDetailPage> createState() => _ArtworkDetailPageState();
}

class _ArtworkDetailPageState extends State<ArtworkDetailPage> {
  late ScrollController _scrollController;
  bool _showArtwortReportProblemContainer = true;
  HashSet<String> _accountNumberHash = HashSet.identity();
  AssetToken? currentAsset;

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    super.initState();

    context.read<ArtworkDetailBloc>().add(ArtworkDetailGetInfoEvent(
        widget.payload.ids[widget.payload.currentIndex]));
    context.read<AccountsBloc>().add(FetchAllAddressesEvent());
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
          appBar: getBackAppBar(context,
              onBack: () => Navigator.of(context).pop(),
              action: () {
                if (currentAsset == null) return;
                _showArtworkOptionsDialog(currentAsset!);
              }),
          body: BlocConsumer<ArtworkDetailBloc, ArtworkDetailState>(
              listener: (context, state) {
            final identitiesList =
                state.provenances.map((e) => e.owner).toList();
            if (state.asset?.artistName != null &&
                state.asset!.artistName!.length > 20) {
              identitiesList.add(state.asset!.artistName!);
            }
            currentAsset = state.asset;
            context.read<IdentityBloc>().add(GetIdentityEvent(identitiesList));
          }, builder: (context, state) {
            if (state.asset != null) {
              final identityState = context.watch<IdentityBloc>().state;

              final asset = state.asset!;
              final screenWidth = MediaQuery.of(context).size.width;
              final screenHeight = MediaQuery.of(context).size.height;

              final artistName =
                  asset.artistName?.toIdentityOrMask(identityState.identityMap);

              var subTitle = "";
              if (artistName != null && artistName.isNotEmpty) {
                subTitle = "by $artistName";
              }

              if (asset.edition != 0)
                subTitle += " (${asset.edition}/${asset.maxEdition})";
              final ext = p.extension(asset.thumbnailURL!);

              return Container(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.0),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          asset.title,
                          style: appTextTheme.headline1,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      if (subTitle.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            subTitle,
                            style: appTextTheme.headline3,
                          ),
                        ),
                      ],
                      SizedBox(height: 16.0),
                      GestureDetector(
                        child: Hero(
                            tag: asset.id,
                            child: ext == ".svg"
                                ? Center(
                                    child:
                                        SvgPicture.network(asset.thumbnailURL!))
                                : CachedNetworkImage(
                                    imageUrl: asset.thumbnailURL!,
                                    width: double.infinity,
                                    memCacheWidth: (screenWidth * 3).floor(),
                                    cacheManager: injector<AUCacheManager>(),
                                    placeholder: (context, url) => AspectRatio(
                                      aspectRatio: 1,
                                      child: Container(
                                          color:
                                              Color.fromRGBO(227, 227, 227, 1)),
                                    ),
                                    placeholderFadeInDuration:
                                        Duration(milliseconds: 300),
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) =>
                                        Container(
                                            color: Color.fromRGBO(
                                                227, 227, 227, 1),
                                            padding: EdgeInsets.all(71),
                                            child: Center(
                                              child: SvgPicture.asset(
                                                'assets/images/image_error.svg',
                                                width: 148,
                                                height: 158,
                                              ),
                                            )),
                                  )),
                        onTap: () => Navigator.of(context).pushNamed(
                            AppRouter.artworkPreviewPage,
                            arguments: widget.payload),
                      ),
                      SizedBox(height: 16.0),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 165,
                              height: 48,
                              child: AuOutlinedButton(
                                  text: "VIEW ARTWORK",
                                  onPress: () {
                                    if (injector<ConfigurationService>()
                                        .isImmediatePlaybackEnabled()) {
                                      Navigator.of(context).pop();
                                    } else {
                                      Navigator.of(context).pushNamed(
                                          AppRouter.artworkPreviewPage,
                                          arguments: widget.payload);
                                    }
                                  }),
                            ),
                            SizedBox(height: 40.0),
                            Text(
                              unescape.convert(asset.desc ?? ""),
                              style: appTextTheme.bodyText1,
                            ),
                            asset.source == "feralfile"
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 40.0),
                                      _artworkRightView(context),
                                    ],
                                  )
                                : SizedBox(),
                            state.assetPrice != null
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 40.0),
                                      _valueView(
                                          context, asset, state.assetPrice),
                                    ],
                                  )
                                : SizedBox(),
                            SizedBox(height: 40.0),
                            _metadataView(context, asset, artistName),
                            state.provenances.isNotEmpty
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 40.0),
                                      _provenanceView(
                                          context, state.provenances),
                                    ],
                                  )
                                : SizedBox(),
                            SizedBox(height: 80.0),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            } else {
              return SizedBox();
            }
          }),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _reportNFTProblemContainer(),
        ),
      ],
    );
  }

  Widget _artworkRightView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Rights",
          style: appTextTheme.headline2,
        ),
        SizedBox(height: 16.0),
        Text(
          "Feral File protects artist and collector rights.",
          style: appTextTheme.bodyText1,
        ),
        SizedBox(height: 18.0),
        TextButton(
          style: textButtonNoPadding,
          onPressed: () =>
              launch("https://feralfile.com/docs/artist-collector-rights"),
          child: Text('Learn more on the Artist + Collector Rights page...',
              style: linkStyle.copyWith(
                fontWeight: FontWeight.w500,
              )),
        ),
        SizedBox(height: 23.0),
        _artworkRightItem(context, "Download",
            "As a collector, you have access to a permanent link where you can download the work’s original, full-resolution files and technical details."),
        Divider(height: 32.0),
        _artworkRightItem(context, "Display",
            "Using the artist’s installation guidelines, you have the right to display the work both privately and publicly."),
        Divider(height: 32.0),
        _artworkRightItem(context, "Authenticate",
            "You have the right to be assured of the work’s authenticity. Feral File guarantees the provenance of every edition using a public ledger recorded on the Bitmark blockchain."),
        Divider(height: 32.0),
        _artworkRightItem(context, "Loan or lease",
            "You may grant others the temporary right to display the work."),
        Divider(height: 32.0),
        _artworkRightItem(context, "Resell or transfer",
            "You are entitled to transfer your rights to the work to another collector or entity. Keep in mind that if you resell the work, the artist will earn 10% of the sale and Feral File will earn 5%."),
        Divider(height: 32.0),
        _artworkRightItem(context, "Remain anonymous",
            "While all sales are recorded publicly on the public blockchain, you can use an alias to keep your collection private."),
        Divider(height: 32.0),
        _artworkRightItem(context, "Respect the artist’s rights",
            "Feral File protects artists by forefronting their rights, just like we forefront your rights as a collector. Learn more on the Artist + Collector Rights page."),
      ],
    );
  }

  Widget _artworkRightItem(BuildContext context, String name, String body) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              name,
              style: appTextTheme.headline4,
            ),
          ],
        ),
        SizedBox(height: 16.0),
        Text(
          body,
          textAlign: TextAlign.start,
          style: appTextTheme.bodyText1,
        ),
      ],
    );
  }

  Widget _valueView(
      BuildContext context, AssetToken asset, AssetPrice? assetPrice) {
    var changedPriceText = "";
    var roiText = "";
    if (assetPrice != null && assetPrice.minPrice != 0) {
      final changedPrice = assetPrice.minPrice - assetPrice.purchasedPrice;
      changedPriceText =
          "${changedPrice >= 0 ? "+" : ""}$changedPrice ${assetPrice.currency.toUpperCase()}";

      if (assetPrice.purchasedPrice == 0) {
        roiText = "+100%";
      } else {
        final roi = (changedPrice / assetPrice.purchasedPrice) * 100;
        roiText = "${roi >= 0 ? "+" : ""}${roi.toStringAsFixed(2)}%";
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Value",
          style: appTextTheme.headline2,
        ),
        if (assetPrice != null) ...[
          SizedBox(height: 16.0),
          _rowItem(context, "Purchase price",
              "${assetPrice.purchasedPrice} ${assetPrice.currency.toUpperCase()}")
        ],
        if (assetPrice != null &&
            assetPrice.listingPrice > 0 &&
            assetPrice.onSale == true) ...[
          Divider(height: 32.0),
          _rowItem(context, "Listed for resale",
              "${assetPrice.listingPrice} ${assetPrice.currency.toUpperCase()}"),
        ],
        if (assetPrice != null && assetPrice.minPrice != 0) ...[
          Divider(height: 32.0),
          _rowItem(context, "Estimated value\n(floor price)",
              "${assetPrice.minPrice} ${assetPrice.currency.toUpperCase()}"),
        ],
        if (changedPriceText.isNotEmpty) ...[
          Divider(height: 32.0),
          _rowItem(context, "Change (\$)", changedPriceText),
        ],
        if (roiText.isNotEmpty) ...[
          Divider(height: 32.0),
          _rowItem(context, "Return on investment (ROI)", roiText),
        ],
      ],
    );
  }

  Widget _metadataView(
      BuildContext context, AssetToken asset, String? artistName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Metadata",
          style: appTextTheme.headline2,
        ),
        SizedBox(height: 16.0),
        _rowItem(context, "Title", asset.title),
        if (artistName != null) ...[
          Divider(height: 32.0),
          _rowItem(
            context,
            "Artist",
            artistName,
            // some FF's artist set multiple links
            // Discussion thread: https://bitmark.slack.com/archives/C01EPPD07HU/p1648698027564299
            tapLink: asset.artistURL?.split(" & ").first,
          ),
        ],
        (asset.maxEdition ?? 0) > 0
            ? Column(
                children: [
                  Divider(height: 32.0),
                  _rowItem(context, "Edition number", asset.edition.toString()),
                  Divider(height: 32.0),
                  _rowItem(
                      context, "Edition size", asset.maxEdition.toString()),
                ],
              )
            : SizedBox(),
        Divider(height: 32.0),
        _rowItem(
          context,
          "Token",
          polishSource(asset.source ?? ""),
          tapLink: asset.assetURL,
        ),
        Divider(height: 32.0),
        _rowItem(
          context,
          "Contract",
          asset.blockchain.capitalize(),
          tapLink: asset.blockchainURL,
        ),
        Divider(height: 32.0),
        _rowItem(context, "Medium", asset.medium?.capitalize()),
        Divider(height: 32.0),
        _rowItem(
            context,
            "Date minted",
            asset.mintedAt != null
                ? localTimeStringFromISO8601(asset.mintedAt!)
                : null),
        asset.assetData != null && asset.assetData!.isNotEmpty
            ? Column(
                children: [
                  Divider(height: 32.0),
                  _rowItem(context, "Artwork data", asset.assetData)
                ],
              )
            : SizedBox(),
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Provenance",
                    style: appTextTheme.headline2,
                  ),
                  SizedBox(height: 23.0),
                  ...provenances.map((el) {
                    final identity = identityState.identityMap[el.owner];
                    final identityTitle =
                        el.owner.toIdentityOrMask(identityState.identityMap);
                    final youTitle =
                        _accountNumberHash.contains(el.owner) ? " (You)" : "";
                    final provenanceTitle = identityTitle ?? '' + youTitle;
                    final onNameTap = () => identity != null
                        ? UIHelper.showIdentityDetailDialog(context,
                            name: identity, address: el.owner)
                        : null;
                    return Column(
                      children: [
                        _rowItem(context, provenanceTitle,
                            localTimeString(el.timestamp),
                            subTitle: el.blockchain.toUpperCase(),
                            tapLink: el.txURL,
                            onNameTap: onNameTap),
                        Divider(height: 32.0),
                      ],
                    );
                  }).toList()
                ],
              );
            }));
  }

  Widget _rowItem(BuildContext context, String name, String? value,
      {String? subTitle,
      Function()? onNameTap,
      String? tapLink,
      Function()? onValueTap}) {
    if (onValueTap == null && tapLink != null) {
      final uri = Uri.parse(tapLink);
      onValueTap = () => launch(uri.toString());
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                child: Text(name, style: appTextTheme.headline4),
                onTap: onNameTap,
              ),
              if (subTitle != null) ...[
                SizedBox(height: 2),
                Text(subTitle,
                    style: appTextTheme.headline4?.copyWith(fontSize: 12)),
              ]
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                  child: GestureDetector(
                child: Text(
                  value ?? "",
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color:
                          onValueTap != null ? Colors.black : Color(0xFF828080),
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      fontFamily: "IBMPlexMono",
                      height: 1.377),
                ),
                onTap: onValueTap,
              )),
              if (onValueTap != null) ...[
                SizedBox(width: 8.0),
                SvgPicture.asset('assets/images/iconForward.svg'),
              ]
            ],
          ),
        )
      ],
    );
  }

  Widget _reportNFTProblemContainer() {
    return GestureDetector(
      onTap: () => _showReportIssueDialog(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _showArtwortReportProblemContainer ? 50 : 0,
        child: Container(
          alignment: Alignment.bottomCenter,
          padding: EdgeInsets.fromLTRB(0, 15, 0, 18),
          color: Color(0xFFEDEDED),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('ANY PROBLEMS WITH THIS NFT?', style: appTextTheme.caption),
              SizedBox(
                width: 4,
              ),
              SvgPicture.asset("assets/images/iconSharpFeedback.svg"),
            ],
          ),
        ),
      ),
    );
  }

  // MARK: REPORT RENDERING ISSUE
  void _showReportIssueDialog() {
    if (currentAsset == null) return;
    UIHelper.showDialog(
        context,
        "Report issue?",
        ReportRenderingIssueWidget(
          token: currentAsset!,
          onReported: (issueID) {
            showErrorDialog(
              context,
              "🤔",
              "We have automatically filed the rendering issue, and we will look into it. If you require further support or want to tell us more about the problem, please tap the button below.",
              "GET SUPPORT",
              () => Navigator.of(context).pushNamed(
                AppRouter.supportThreadPage,
                arguments: DetailIssuePayload(
                    reportIssueType: ReportIssueType.ReportNFTIssue,
                    issueID: issueID),
              ),
              "CLOSE",
            );
          },
        ),
        isDismissible: true);
  }

  void _showArtworkOptionsDialog(AssetToken asset) {
    final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);

    UIHelper.showDialog(
      context,
      "Options",
      Container(
        child: Column(
          children: [
            InkWell(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(asset.isHidden() ? 'Unhide artwork' : 'Hide artwork',
                      style: theme.textTheme.headline4),
                  Icon(Icons.navigate_next, color: Colors.white),
                ],
              ),
              onTap: () async {
                final appDatabase =
                    injector<NetworkConfigInjector>().I<AppDatabase>();
                if (asset.isHidden()) {
                  asset.hidden = null;
                } else {
                  asset.hidden = 1;
                }
                await appDatabase.assetDao.updateAsset(asset);

                Navigator.of(context).pop();
                UIHelper.showHideArtworkResultDialog(context, asset.isHidden(),
                    onOK: () {
                  Navigator.of(context).popUntil((route) =>
                      route.settings.name == AppRouter.homePage ||
                      route.settings.name == AppRouter.homePageNoTransition);
                });
              },
            ),
            Divider(height: 20, color: Colors.white),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "CANCEL",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: "IBMPlexMono"),
              ),
            ),
          ],
        ),
      ),
      isDismissible: true,
    );
  }
}

class ArtworkDetailPayload {
  final List<String> ids;
  final int currentIndex;

  ArtworkDetailPayload(this.ids, this.currentIndex);

  ArtworkDetailPayload copyWith({
    List<String>? ids,
    int? currentIndex,
  }) {
    return ArtworkDetailPayload(
      ids ?? this.ids,
      currentIndex ?? this.currentIndex,
    );
  }
}
