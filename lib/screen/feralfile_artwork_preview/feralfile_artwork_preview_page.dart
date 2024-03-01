import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/feralfile_artwork_preview_widget.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
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
              child: FeralfileArtworkPreviewWidget(
                payload: FeralFileArtworkPreviewWidgetPayload(
                  artwork: widget.payload.artwork,
                  isMute: true,
                  isScrollable: widget.payload.artwork.isScrollablePreviewURL,
                ),
              ),
            ),
          ],
        ),
      );
}

class FeralFileArtworkPreviewPagePayload {
  final Artwork artwork;

  const FeralFileArtworkPreviewPagePayload({required this.artwork});
}
