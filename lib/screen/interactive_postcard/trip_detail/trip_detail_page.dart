import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nft_collection/models/asset_token.dart';

class TripDetailPayload {
  final AssetToken assetToken;
  final int stampIndex;

  TripDetailPayload({required this.assetToken, required this.stampIndex});
}

class TripDetailPage extends StatefulWidget {
  final TripDetailPayload payload;

  const TripDetailPage({super.key, required this.payload});

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  late int _stampIndex;

  @override
  void initState() {
    super.initState();
    _stampIndex = widget.payload.stampIndex;
  }

  @override
  Widget build(BuildContext context) {
    final title = "stamp_".tr(args: [(_stampIndex + 1).toString()]);
    return Scaffold(
      backgroundColor: POSTCARD_BACKGROUND_COLOR,
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
        title: title,
        backgroundColor: POSTCARD_BACKGROUND_COLOR,
        withDivider: false,
      ),
      body: Padding(
        padding: ResponsiveLayout.pageEdgeInsets,
        child: Column(
          children: [
            addTitleSpace(),
            AbsorbPointer(
              child: AspectRatio(
                aspectRatio: STAMP_ASPECT_RATIO,
                child: PostcardViewWidget(
                  assetToken: widget.payload.assetToken,
                  zoomIndex: _stampIndex,
                  backgroundColor: POSTCARD_BACKGROUND_COLOR,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
