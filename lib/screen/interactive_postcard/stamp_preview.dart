import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
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
    final postcardMetadata = PostcardMetadata.fromJson(
        jsonDecode(widget.payload.asset.artworkMetadata!));
    index = postcardMetadata.locationInformation.length - 1;
  }

  Future<void> fetchPostcard() async {
    String emptyPostcardUrl = widget.payload.asset.getPreviewUrl()!;

    http.Response response = await http.get(Uri.parse(emptyPostcardUrl));
    final bytes = response.bodyBytes;
    postcardData = bytes;
    await pasteStamp();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (stampedPostcardData == null) {
      return Scaffold(
        backgroundColor: AppColor.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/loading.gif",
                width: 52,
                height: 52,
              ),
              const SizedBox(height: 20),
              Text(
                "loading...".tr(),
                style: theme.textTheme.ppMori400Black14,
              )
            ],
          ),
        ),
      );
    }
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
            Padding(
              padding:
                  ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
              child: Column(
                children: [
                  Text("finalize_note".tr(),
                      style: theme.textTheme.ppMori400Black14
                          .copyWith(color: AppColor.auQuickSilver)),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: "finalize_postcard".tr(),
                    enabled: stamped,
                    onTap: () async {
                      await _sendPostcard();
                    },
                  ),
                ],
              ),
            )
          ],
        ));
  }

  Future<void> pasteStamp() async {
    final postcardImage = await decodeFuture(postcardData!);
    final stampImageResized =
        await resizeImage(ResizeImageParams(widget.payload.image, 520, 546));

    var image = await compositeImageAt(CompositeImageParams(
        postcardImage, stampImageResized, 210, 212, index, 490, 546));
    stamped = true;
    stampedPostcardData = await encodeImage(image);
    setState(() {});
  }

  Future<void> _sendPostcard() async {
    if (!stamped) return;
    String dir = (await getTemporaryDirectory()).path;
    File imageFile = File('$dir/postcardImage.png');
    final imageData = await imageFile.writeAsBytes(stampedPostcardData!);
    final owner =
        await widget.payload.asset.getOwnerWallet(checkContract: false);
    if (owner == null) return;
    final result = await injector<PostcardService>().stampPostcard(
        widget.payload.asset.tokenId ?? "",
        owner.first,
        owner.second,
        imageData,
        widget.payload.location);
    if (result) {
      if (!mounted) return;
      injector<NavigationService>().popUntilHomeOrSettings();
    }
  }
}

Future<img.Image> compositeImageAt(CompositeImageParams compositeImages) async {
  return await compute(compositeImagesAt, compositeImages);
}

img.Image compositeImagesAt(CompositeImageParams param) {
  final row = param.index ~/ 9;
  final col = param.index % 9;
  final dstX = param.x + col * param.w;
  final dstY = param.y + row * param.h;

  return img.compositeImage(param.dst, param.src, dstX: dstX - 10, dstY: dstY);
}

Future<img.Image> resizeImage(ResizeImageParams resizeImageParams) async {
  return await compute(resizeImageAt, resizeImageParams);
}

img.Image resizeImageAt(ResizeImageParams param) {
  return img.copyResize(param.image, width: param.width, height: param.height);
}

Future<img.Image> decodeFuture(Uint8List data) async {
  return await compute(_decodeImage, data);
}

img.Image _decodeImage(Uint8List data) {
  return img.decodeImage(data)!;
}

// isolate encodeImage
Future<Uint8List> encodeImage(img.Image image) async {
  return await compute(_encodeImage, image);
}

Uint8List _encodeImage(img.Image image) {
  return img.encodePng(image);
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
  final int index;
  final int w;
  final int h;

  CompositeImageParams(
      this.dst, this.src, this.x, this.y, this.index, this.w, this.h);
}

class ResizeImageParams {
  final img.Image image;
  final int width;
  final int height;

  ResizeImageParams(this.image, this.width, this.height);
}
