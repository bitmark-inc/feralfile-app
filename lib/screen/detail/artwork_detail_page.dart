import 'package:autonomy_flutter/model/asset.dart';
import 'package:autonomy_flutter/model/asset_price.dart';
import 'package:autonomy_flutter/model/bitmark.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_state.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_page.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/view/au_outlined_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ArtworkDetailPage extends StatelessWidget {
  static const tag = "artwork_detail";

  final Asset asset;

  const ArtworkDetailPage({Key? key, required this.asset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context
        .read<ArtworkDetailBloc>()
        .add(ArtworkDetailGetInfoEvent(asset.id));

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.0),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  asset.projectMetadata.latest.title,
                  style: Theme.of(context).textTheme.headline1,
                ),
              ),
              SizedBox(height: 8.0),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "by ${asset.projectMetadata.latest.artistName} (${asset.edition}/${asset.projectMetadata.latest.maxEdition})",
                  style: Theme.of(context).textTheme.headline3,
                ),
              ),
              SizedBox(height: 16.0),
              Image.network(asset.projectMetadata.latest.thumbnailUrl),
              SizedBox(height: 16.0),
              BlocBuilder<ArtworkDetailBloc, ArtworkDetailState>(
                builder: (context, state) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 165,
                          child: AuOutlinedButton(
                              text: "VIEW ARTWORK \u25b6", onPress: () {
                            Navigator.of(context).pushNamed(ArtworkPreviewPage.tag, arguments: asset);
                          }),
                        ),
                        SizedBox(height: 40.0),
                        Text(
                          asset.projectMetadata.latest.description,
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        SizedBox(height: 40.0),
                        _artworkRightView(context),
                        SizedBox(height: 40.0),
                        _valueView(context, state.assetPrice),
                        SizedBox(height: 40.0),
                        _metadataView(context),
                        SizedBox(height: 40.0),
                        _provenanceView(context, state.provenances),
                        SizedBox(height: 40.0),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _artworkRightView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Rights",
          style: Theme.of(context).textTheme.headline2,
        ),
        SizedBox(height: 16.0),
        Text(
          "You’ll retain these rights forever. Your rights are guaranteed in perpetuity until you resell or transfer ownership of the work.",
          style: Theme.of(context).textTheme.bodyText1,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.headline5,
            ),
            Icon(CupertinoIcons.forward)
          ],
        ),
        SizedBox(height: 16.0),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyText1,
        ),
      ],
    );
  }

  Widget _valueView(BuildContext context, AssetPrice? assetPrice) {

    final changedPrice = (assetPrice?.minPrice ?? 0) - (assetPrice?.purchasedPrice ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Value",
          style: Theme.of(context).textTheme.headline2,
        ),
        SizedBox(height: 16.0),
        _rowItem(context, "Initial price",
            "${asset.projectMetadata.latest.basePrice} ${asset.projectMetadata.latest.baseCurrency.toUpperCase()}"),
        Divider(height: 32.0),
        _rowItem(context, "Purchase price", assetPrice != null ? "${assetPrice.purchasedPrice} ${assetPrice.currency.toUpperCase()}" : ""),
        Divider(height: 32.0),
        _rowItem(context, "Listed for resale", assetPrice != null && assetPrice.onSale == true ? "${assetPrice.listingPrice} ${assetPrice.currency.toUpperCase()}" : "N/A"),
        Divider(height: 32.0),
        _rowItem(context, "Estimated value\n(floor price)", assetPrice != null ? "${assetPrice.minPrice} ${assetPrice.currency.toUpperCase()}" : ""),
        Divider(height: 32.0),
        _rowItem(context, "Change (\$)", "${changedPrice >= 0 ? "+" : ""}$changedPrice ${assetPrice?.currency.toUpperCase()}"),
        Divider(height: 32.0),
        _rowItem(context, "Change (%)", "${changedPrice >= 0 ? "+" : ""}${changedPrice * 100 / (assetPrice?.purchasedPrice ?? 1)}%"),
      ],
    );
  }

  Widget _metadataView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Metadata",
          style: Theme.of(context).textTheme.headline2,
        ),
        SizedBox(height: 16.0),
        _rowItem(context, "Title", asset.projectMetadata.latest.title),
        Divider(height: 32.0),
        _rowItem(context, "Artist", asset.projectMetadata.latest.artistName),
        Divider(height: 32.0),
        _rowItem(context, "Edition number", asset.edition.toString()),
        Divider(height: 32.0),
        _rowItem(context, "Edition size",
            asset.projectMetadata.latest.maxEdition.toString()),
        Divider(height: 32.0),
        _rowItem(context, "Source",
            asset.projectMetadata.latest.source.capitalize()),
        Divider(height: 32.0),
        _rowItem(context, "Blockchain", asset.blockchain.capitalize()),
        Divider(height: 32.0),
        _rowItem(context, "Medium",
            asset.projectMetadata.latest.medium.capitalize()),
        Divider(height: 32.0),
        _rowItem(context, "Date minted", asset.mintedAt.toString()),
        Divider(height: 32.0),
        _rowItem(context, "Date collected", ""),
        Divider(height: 32.0),
        _rowItem(
            context, "Artwork data", asset.projectMetadata.latest.assetData),
      ],
    );
  }

  Widget _provenanceView(BuildContext context, List<Provenance> provenances) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Provenance",
          style: Theme.of(context).textTheme.headline2,
        ),
        SizedBox(height: 16.0),
        ...provenances
            .map((el) => Column(
          children: [
            _rowItem(
                context, el.owner.mask(4), el.createdAt.toString()),
            Divider(height: 32.0),
          ],
        ))
            .toList()
      ],
    );
  }

  Widget _rowItem(BuildContext context, String name, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(name, style: Theme.of(context).textTheme.headline5),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color: Color(0xFF828080),
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      fontFamily: "IBMPlexMono"),
                ),
              ),
              // SizedBox(width: 8.0),
              // Icon(CupertinoIcons.forward)
            ],
          ),
        )
      ],
    );
  }
}
