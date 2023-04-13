import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/stamp_preview.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/isolate.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_theme/style/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:nft_collection/models/asset_token.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

class HandSignaturePage extends StatefulWidget {
  static const String handSignaturePage = "hand_signature_page";
  final HandSignaturePayload payload;

  const HandSignaturePage({Key? key, required this.payload}) : super(key: key);

  @override
  State<HandSignaturePage> createState() => _HandSignaturePageState();
}

class _HandSignaturePageState extends State<HandSignaturePage> {
  final GlobalKey<SfSignaturePadState> signatureGlobalKey = GlobalKey();
  bool didDraw = false;
  bool loading = false;
  Uint8List? resizedStamp;

  @override
  void initState() {
    super.initState();
    resizeStamp();
  }

  Future<void> resizeStamp() async {
    final image = await resizeImage(
        ResizeImageParams(img.decodePng(widget.payload.image)!, 400, 400));
    setState(() {
      resizedStamp = img.encodePng(image);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primaryBlack,
      body: RotatedBox(
        quarterTurns: -1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 15, 50, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: AppColor.white,
                  child: Stack(
                    children: [
                      Visibility(
                        visible: !didDraw,
                        child: Align(
                            child: SvgPicture.asset(
                                "assets/images/sign_here.svg",
                                fit: BoxFit.scaleDown)),
                      ),
                      SfSignaturePad(
                        key: signatureGlobalKey,
                        minimumStrokeWidth: 9,
                        maximumStrokeWidth: 9,
                        strokeColor: Colors.black,
                        backgroundColor: Colors.transparent,
                        onDrawEnd: () {
                          setState(() {
                            didDraw = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: AppColor.auGreyBackground,
                ),
                child: Row(
                  children: [
                    IconButton(
                      padding: const EdgeInsets.all(0),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      alignment: Alignment.center,
                      icon: SvgPicture.asset(
                        'assets/images/icon_back.svg',
                        color: AppColor.white,
                      ),
                    ),
                    Expanded(
                      child: PostcardButton(
                        onTap: _handleClearButtonPressed,
                        text: "clear".tr(),
                        color: AppColor.white,
                        textColor: AppColor.auGrey,
                      ),
                    ),
                    Expanded(
                      child: PostcardButton(
                        isProcessing: loading,
                        enabled: didDraw && resizedStamp != null,
                        onTap: _handleSaveButtonPressed,
                        text: "sign_and_stamp".tr(),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _handleClearButtonPressed() {
    setState(() {
      didDraw = false;
    });
    signatureGlobalKey.currentState!.clear();
  }

  void _handleSaveButtonPressed() async {
    setState(() {
      loading = true;
    });
    final asset = widget.payload.asset;
    final signatureWith = MediaQuery.of(context).size.height.toInt();
    final ratio = 400.0 / signatureWith.toDouble();
    final data =
        await signatureGlobalKey.currentState!.toImage(pixelRatio: ratio * 0.9);
    final bytes = await data.toByteData(format: ImageByteFormat.png);

    final image =
        await compositeImage([resizedStamp!, bytes!.buffer.asUint8List()]);

    String dir = (await getTemporaryDirectory()).path;
    File imageFile = File('$dir/postcardImage.png');
    File metadataFile = File('$dir/metadata.json');
    final Map<String, dynamic> metadata = {
      "address": widget.payload.location,
      "stampedAt": DateTime.now().toIso8601String()
    };
    await metadataFile.writeAsString(jsonEncode(metadata));
    final imageData = await imageFile.writeAsBytes(img.encodePng(image));
    final owner = await asset.getOwnerWallet(checkContract: false);
    if (!mounted) return;
    UIHelper.hideInfoDialog(context);
    Navigator.of(context).pushNamed(AppRouter.claimedPostcardDetailsPage,
        arguments: ArtworkDetailPayload([asset.identity], 0));
    if (owner == null) {
      if (!mounted) return;
      UIHelper.hideInfoDialog(context);
      return;
    }
    final counter = 0; //asset.postcardMetadata.counter;
    final result = injector<PostcardService>().stampPostcard(
        asset.tokenId ?? "",
        owner.first,
        owner.second,
        imageData,
        metadataFile,
        widget.payload.location,
        counter);
    imageFile.delete();
    metadataFile.delete();

    if (!mounted) return;
    Navigator.of(context).pushNamed(StampPreview.tag,
        arguments: StampPreviewPayload(
          image,
          widget.payload.asset,
          widget.payload.location,
        ));
  }
}

class HandSignaturePayload {
  final Uint8List image;
  final AssetToken asset;
  final Position? location;
  final String address;

  HandSignaturePayload(this.image, this.asset, this.location, this.address);
}
