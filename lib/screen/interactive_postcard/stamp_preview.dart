import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:nft_collection/models/asset_token.dart';
import 'package:path_provider/path_provider.dart';

class StampPreview extends StatefulWidget {
  static const String tag = "stamp_preview";
  final StampPreviewPayload payload;
  static const double cellSize = 20.0;

  const StampPreview({Key? key, required this.payload}) : super(key: key);

  @override
  State<StampPreview> createState() => _StampPreviewState();
}

class _StampPreviewState extends State<StampPreview> {
  Uint8List? postcardData;
  Uint8List? stampedPostcardData;
  int index = 0;
  bool stamped = false;

  @override
  void initState() {
    super.initState();
    fetchPostcard();
  }

  Future<void> fetchPostcard() async {
    await rootBundle.load("assets/images/empty_postcard.png").then((value) {
      postcardData = value.buffer.asUint8List();
      setState(() {
        stampedPostcardData = postcardData;
      });
    });
    await pasteStamp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColor.primaryBlack,
        appBar: getBackAppBar(context, title: "send".tr(), onBack: () {
          Navigator.of(context).pop();
        }, isWhite: false),
        body: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  stampedPostcardData != null
                      ? Image.memory(
                          stampedPostcardData!,
                          fit: BoxFit.cover,
                        )
                      : const SizedBox(),
                ],
              ),
            ),
            PrimaryButton(
              text: "send_postcard".tr(),
              onTap: () async {
                await _sendPostcard();
              },
            )
          ],
        ));
  }

  Future<void> pasteStamp() async {
    final postcardImage = img.decodePng(postcardData!);
    final stampImageResized =
        img.copyResize(widget.payload.image, width: 490, height: 546);

    final image = await compositeImageAt(
        CompositeImageParams(postcardImage!, stampImageResized, 210, 212));
    setState(() {
      stamped = true;
      stampedPostcardData = img.encodePng(image);
    });
  }

  Future<void> _sendPostcard() async {
    if (!stamped) return;
    String dir = (await getTemporaryDirectory()).path;
    File imageFile = File('$dir/postcardImage.png');
    final imageData =
        await imageFile.writeAsBytes(stampedPostcardData!);
    final owner = await widget.payload.asset.getOwnerWallet();
    if (owner == null) return;
    final result = await injector<PostcardService>().stampPostcard(
        owner.first, owner.second, imageData, widget.payload.location);
    if (result) {
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }
}

Future<img.Image> compositeImageAt(CompositeImageParams compositeImages) async {
  return await compute(compositeImagesAt, compositeImages);
}

img.Image compositeImagesAt(CompositeImageParams param) {
  return img.compositeImage(param.dst, param.src, dstX: param.x, dstY: param.y);
}

class StampPreviewPayload {
  final img.Image image;
  final AssetToken asset;
  final Position? location;

  StampPreviewPayload(this.image, this.asset, this.location);
}

class CompositeImageParams {
  final img.Image dst;
  final img.Image src;
  final int x;
  final int y;

  CompositeImageParams(this.dst, this.src, this.x, this.y);
}
