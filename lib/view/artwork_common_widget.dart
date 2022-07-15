import 'dart:collection';

import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/model/asset_price.dart';
import 'package:autonomy_flutter/model/provenance.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/detail/report_rendering_issue/any_problem_nft_widget.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/au_cached_manager.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:nft_rendering/nft_rendering.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../common/injector.dart';

String getEditionSubTitle(AssetToken token) {
  if (token.edition == 0) return "";
  return " (${token.edition}/${token.maxEdition})";
}

Widget tokenThumbnailWidget(BuildContext context, AssetToken token) {
  final ext = p.extension(token.thumbnailURL!);
  final screenWidth = MediaQuery.of(context).size.width;

  return Hero(
    tag: token.id,
    child: ext == ".svg"
        ? Center(
            child: SvgPicture.network(token.thumbnailURL!,
                placeholderBuilder: (context) => placeholder()))
        : CachedNetworkImage(
            imageUrl: token.thumbnailURL!,
            width: double.infinity,
            memCacheWidth: (screenWidth * 3).floor(),
            cacheManager: injector<AUCacheManager>(),
            placeholder: (context, url) => placeholder(),
            placeholderFadeInDuration: Duration(milliseconds: 300),
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => Container(
              color: Color.fromRGBO(227, 227, 227, 1),
              padding: EdgeInsets.all(71),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/image_error.svg',
                  width: 148,
                  height: 158,
                ),
              ),
            ),
          ),
  );
}

Widget tokenGalleryThumbnailWidget(
    BuildContext context, AssetToken token, int cachedImageSize) {
  final ext = p.extension(token.thumbnailURL!);

  return Hero(
    tag: token.id,
    child: ext == ".svg"
        ? SvgPicture.network(token.galleryThumbnailURL!,
            placeholderBuilder: (context) =>
                Container(color: Color.fromRGBO(227, 227, 227, 1)))
        : CachedNetworkImage(
            imageUrl: token.galleryThumbnailURL!,
            fit: BoxFit.cover,
            memCacheHeight: cachedImageSize,
            memCacheWidth: cachedImageSize,
            cacheManager: injector<AUCacheManager>(),
            placeholder: (context, index) =>
                Container(color: Color.fromRGBO(227, 227, 227, 1)),
            placeholderFadeInDuration: Duration(milliseconds: 300),
            errorWidget: (context, url, error) => Container(
                color: Color.fromRGBO(227, 227, 227, 1),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/image_error.svg',
                    width: 75,
                    height: 75,
                  ),
                )),
          ),
  );
}

Widget placeholder() {
  return AspectRatio(
    aspectRatio: 1,
    child: Container(color: Color.fromRGBO(227, 227, 227, 1)),
  );
}

Widget reportNFTProblemContainer(
    AssetToken? token, bool isShowingArtwortReportProblemContainer) {
  if (token == null) return SizedBox();
  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    height: isShowingArtwortReportProblemContainer ? 62 : 0,
    child: AnyProblemNFTWidget(
      asset: token,
      theme: AuThemeManager.get(AppTheme.anyProblemNFTTheme),
    ),
  );
}

INFTRenderingWidget buildRenderingWidget(AssetToken asset) {
  String mimeType = "";
  switch (asset.medium) {
    case "image":
      final ext = p.extension(asset.previewURL!);
      if (ext == ".svg") {
        mimeType = "svg";
      } else {
        mimeType = "image";
      }
      break;
    case "video":
      mimeType = "video";
      break;
    default:
      mimeType = asset.mimeType ?? "";
  }
  final renderingWidget = typesOfNFTRenderingWidget(mimeType);

  renderingWidget.setRenderWidgetBuilder(RenderingWidgetBuilder(
    previewURL: asset.previewURL,
    loadingWidget: previewPlaceholder,
    cacheManager: injector<AUCacheManager>(),
  ));

  return renderingWidget;
}

Widget get previewPlaceholder {
  return Center(
    child: loadingIndicator(valueColor: Colors.white),
  );
}

Widget debugInfoWidget(AssetToken? token) {
  if (token == null) return SizedBox();

  return FutureBuilder<bool>(
      future: isAppCenterBuild().then((value) {
        if (value == false) return Future.value(false);

        return injector<ConfigurationService>().showTokenDebugInfo();
      }),
      builder: (context, snapshot) {
        if (snapshot.data == false) return SizedBox();

        TextButton _buildInfo(String text, String value) {
          return TextButton(
            onPressed: () async {
              Vibrate.feedback(FeedbackType.light);

              if (await canLaunch(value)) {
                launch(value, forceSafariVC: false);
              } else {
                Clipboard.setData(ClipboardData(text: value));
              }
            },
            child: Text('$text:  $value'),
          );
        }

        return Column(
          children: [
            addDivider(),
            Text(
              "DEBUG INFO",
              style: appTextTheme.headline4,
            ),
            _buildInfo('IndexerID', token.id),
            _buildInfo('galleryThumbnailURL', token.galleryThumbnailURL ?? ''),
            _buildInfo('thumbnailURL', token.thumbnailURL ?? ''),
            _buildInfo('previewURL', token.previewURL ?? ''),
            addDivider(),
          ],
        );
      });
}

Widget artworkDetailsRightSection(BuildContext context, AssetToken token) {
  return token.source == "feralfile"
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [SizedBox(height: 40.0), _artworkRightView(context)],
        )
      : SizedBox();
}

Widget artworkDetailsValueSection(
    BuildContext context, AssetToken token, AssetPrice? assetPrice) {
  return assetPrice != null
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40.0),
            _valueView(context, token, assetPrice),
          ],
        )
      : SizedBox();
}

Widget artworkDetailsMetadataSection(
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
                _rowItem(context, "Edition size", asset.maxEdition.toString()),
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

Widget artworkDetailsProvenanceSectionNotEmpty(
    BuildContext context,
    List<Provenance> provenances,
    HashSet<String> youAddresses,
    Map<String, String> identityMap) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 40.0),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Provenance",
            style: appTextTheme.headline2,
          ),
          SizedBox(height: 23.0),
          ...provenances.map((el) {
            final identity = identityMap[el.owner];
            final identityTitle = el.owner.toIdentityOrMask(identityMap);
            final youTitle = youAddresses.contains(el.owner) ? " (You)" : "";
            final provenanceTitle = identityTitle ?? '' + youTitle;
            final onNameTap = () => identity != null
                ? UIHelper.showIdentityDetailDialog(context,
                    name: identity, address: el.owner)
                : null;
            return Column(
              children: [
                _rowItem(
                    context, provenanceTitle, localTimeString(el.timestamp),
                    subTitle: el.blockchain.toUpperCase(),
                    tapLink: el.txURL,
                    onNameTap: onNameTap),
                Divider(height: 32.0),
              ],
            );
          }).toList()
        ],
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

Widget _valueView(
    BuildContext context, AssetToken asset, AssetPrice? assetPrice) {
  var changedPriceText = "";
  var roiText = "";
  if (assetPrice != null && assetPrice.minPrice != 0) {
    final changedPrice = assetPrice.minPrice - assetPrice.purchasedPrice;
    changedPriceText =
        "${changedPrice >= 0 ? "+" : ""}${changedPrice.toStringAsFixed(2)} ${assetPrice.currency.toUpperCase()}";

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
            "${assetPrice.purchasedPrice.toStringAsFixed(2)} ${assetPrice.currency.toUpperCase()}")
      ],
      if (assetPrice != null &&
          assetPrice.listingPrice > 0 &&
          assetPrice.onSale == true) ...[
        Divider(height: 32.0),
        _rowItem(context, "Listed for resale",
            "${assetPrice.listingPrice.toStringAsFixed(2)} ${assetPrice.currency.toUpperCase()}"),
      ],
      if (assetPrice != null && assetPrice.minPrice != 0) ...[
        Divider(height: 32.0),
        _rowItem(context, "Estimated value\n(floor price)",
            "${assetPrice.minPrice.toStringAsFixed(2)} ${assetPrice.currency.toUpperCase()}"),
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

Widget previewCloseIcon(BuildContext context) {
  return IconButton(
    onPressed: () => Navigator.of(context).pop(),
    icon: closeIcon(color: Colors.white),
  );
}
