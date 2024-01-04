import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_widget.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';

class FeralFileArtworkPreviewPage extends StatefulWidget {
  const FeralFileArtworkPreviewPage({required this.payload, super.key});

  final FeralFileArtworkPreviewPagePayload payload;

  @override
  State<FeralFileArtworkPreviewPage> createState() =>
      _FeralFileArtworkPreviewPageState();
}

class _FeralFileArtworkPreviewPageState
    extends State<FeralFileArtworkPreviewPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: getFFAppBar(
          context,
          onBack: () => Navigator.pop(context),
        ),
    backgroundColor: AppColor.primaryBlack,
        body: Column(
          children: [
            Expanded(
              child: ArtworkPreviewWidget(
                identity: ArtworkIdentity(widget.payload.tokenId, ''),
                useIndexer: true,
              ),
            ),
          ],
        ),
      );
}

class FeralFileArtworkPreviewPagePayload {
  final Artwork artwork;
  final String tokenId;

  const FeralFileArtworkPreviewPagePayload(
      {required this.artwork, required this.tokenId});
}
