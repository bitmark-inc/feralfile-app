import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/model/asset_price.dart';
import 'package:autonomy_flutter/model/bitmark.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_state.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_page.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_outlined_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:url_launcher/url_launcher.dart';

class ArtworkDetailPage extends StatelessWidget {
  static const tag = "artwork_detail";

  final ArtworkDetailPayload payload;

  const ArtworkDetailPage({Key? key, required this.payload}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final unescape = HtmlUnescape();
    context
        .read<ArtworkDetailBloc>()
        .add(ArtworkDetailGetInfoEvent(payload.ids[payload.currentIndex]));

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: BlocConsumer<ArtworkDetailBloc, ArtworkDetailState>(
          listener: (context, state) => context
              .read<IdentityBloc>()
              .add(GetIdentityEvent(state.provenances.map((e) => e.owner))),
          builder: (context, state) {
            if (state.asset != null) {
              final asset = state.asset!;
              final screenWidth = MediaQuery.of(context).size.width;
              final screenHeight = MediaQuery.of(context).size.height;

              return Container(
                child: SingleChildScrollView(
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
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "by ${asset.artistName} (${asset.edition}/${asset.maxEdition})",
                          style: appTextTheme.headline3,
                        ),
                      ),
                      SizedBox(height: 16.0),
                      CachedNetworkImage(
                        imageUrl: asset.thumbnailURL!,
                        width: double.infinity,
                        maxWidthDiskCache: (screenHeight * 3).floor(),
                        memCacheWidth: (screenWidth * 3).floor(),
                        placeholderFadeInDuration: Duration(milliseconds: 300),
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            SizedBox(height: 100),
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
                                  text: "VIEW ARTWORK ‣",
                                  onPress: () {
                                    Navigator.of(context).pushNamed(
                                        ArtworkPreviewPage.tag,
                                        arguments: payload);
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
                            _metadataView(context, asset),
                            asset.blockchain == "bitmark"
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
                            SizedBox(height: 40.0),
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
        RichText(
          text: TextSpan(children: [
            TextSpan(
              style: appTextTheme.bodyText1,
              text:
                  "Feral File protects artist and collector rights. Learn more on the ",
            ),
            TextSpan(
              style: TextStyle(
                  color: Color(0xFF5B5BFF),
                  fontSize: 16,
                  fontFamily: "AtlasGrotesk",
                  height: 1.377),
              text: "Artist + Collector Rights",
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  launch("https://feralfile.com/docs/artist-collector-rights");
                },
            ),
            TextSpan(
              style: appTextTheme.bodyText1,
              text: " page.",
            ),
          ]),
        ),
        SizedBox(height: 16.0),
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
    final changedPrice =
        (assetPrice?.minPrice ?? 0) - (assetPrice?.purchasedPrice ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Value",
          style: appTextTheme.headline2,
        ),
        SizedBox(height: 16.0),
        _rowItem(
            context,
            "Initial price",
            asset.basePrice != null
                ? "${asset.basePrice} ${asset.baseCurrency?.toUpperCase()}"
                : "N/A"),
        Divider(height: 32.0),
        _rowItem(
            context,
            "Purchase price",
            assetPrice != null
                ? "${assetPrice.purchasedPrice} ${assetPrice.currency.toUpperCase()}"
                : ""),
        Divider(height: 32.0),
        _rowItem(
            context,
            "Listed for resale",
            assetPrice != null && assetPrice.onSale == true
                ? "${assetPrice.listingPrice} ${assetPrice.currency.toUpperCase()}"
                : "N/A"),
        Divider(height: 32.0),
        _rowItem(
            context,
            "Estimated value\n(floor price)",
            assetPrice != null
                ? "${assetPrice.minPrice} ${assetPrice.currency.toUpperCase()}"
                : ""),
        Divider(height: 32.0),
        _rowItem(
            context,
            "Change (\$)",
            assetPrice?.minPrice == null
                ? "${changedPrice >= 0 ? "+" : ""}$changedPrice ${assetPrice?.currency.toUpperCase()}"
                : "N/A"),
        Divider(height: 32.0),
        _rowItem(
            context,
            "Change (%)",
            assetPrice?.minPrice == null
                ? "${changedPrice >= 0 ? "+" : ""}${changedPrice * 100 / (assetPrice?.purchasedPrice ?? 1)}%"
                : "N/A"),
      ],
    );
  }

  Widget _metadataView(BuildContext context, AssetToken asset) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Metadata",
          style: appTextTheme.headline2,
        ),
        SizedBox(height: 16.0),
        _rowItem(context, "Title", asset.title),
        Divider(height: 32.0),
        _rowItem(context, "Artist", asset.artistName),
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
        _rowItem(context, "Source", asset.source?.capitalize()),
        Divider(height: 32.0),
        _rowItem(context, "Blockchain", asset.blockchain.capitalize()),
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
        builder: (context, state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Provenance",
                  style: appTextTheme.headline2,
                ),
                SizedBox(height: 16.0),
                ...provenances.map((el) {
                  final identity = state.identityMap[el.owner];
                  final onNameTap = () => identity != null
                      ? UIHelper.showIdentityDetailDialog(context,
                          name: identity, address: el.owner)
                      : null;
                  return Column(
                    children: [
                      _rowItem(context, identity ?? el.owner.mask(4),
                          localTimeString(el.createdAt),
                          onNameTap: onNameTap),
                      Divider(height: 32.0),
                    ],
                  );
                }).toList()
              ],
            ));
  }

  Widget _rowItem(BuildContext context, String name, String? value,
      {Function()? onNameTap, Function()? onValueTap}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GestureDetector(
            child: Text(name, style: appTextTheme.headline4),
            onTap: onNameTap,
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                  child: GestureDetector(
                child: Text(
                  value ?? "",
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color: Color(0xFF828080),
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      fontFamily: "IBMPlexMono"),
                ),
                onTap: onValueTap,
              )),
              // SizedBox(width: 8.0),
              // Icon(CupertinoIcons.forward)
            ],
          ),
        )
      ],
    );
  }
}

class ArtworkDetailPayload {
  final List<String> ids;
  final int currentIndex;

  ArtworkDetailPayload(this.ids, this.currentIndex);
}
