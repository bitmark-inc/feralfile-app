import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/stamp_preview.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/isolate.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/postcard_extension.dart';
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
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.memory(
                          widget.payload.image,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
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
                        text: "sign_postcard".tr(),
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
    final tokenId = asset.tokenId ?? "";
    final address = asset.owner;
    final counter = asset.postcardMetadata.counter;
    final contractAddress = Environment.postcardContractAddress;
    final data = await signatureGlobalKey.currentState!.toImage();
    final bytes = await data.toByteData(format: ImageByteFormat.png);
    final signature = img.decodePng(bytes!.buffer.asUint8List());
    final newHeight = signature!.height * 400 ~/ signature.width;
    final resizedSignature =
        await resizeImage(ResizeImageParams(signature, 400, newHeight));
    final image =
        await compositeImage([resizedStamp!, img.encodePng(resizedSignature)]);
    final dir = (await getApplicationDocumentsDirectory()).path;
    final imagePath = '$dir/${contractAddress}_${tokenId}_${counter}_image.png';
    final metadataPath =
        '$dir/${contractAddress}_${tokenId}_${counter}_metadata.json';
    File imageFile = File(imagePath);
    File metadataFile = File(metadataPath);

    final Map<String, dynamic> metadata = {
      "address": widget.payload.address,
      "stampedAt": DateTime.now().toIso8601String()
    };

    final postcardService = injector<PostcardService>();
    final isMinted = await postcardService.isReceivedSuccess(
        contractAddress: contractAddress,
        address: address,
        tokenId: tokenId,
        counter: counter);
    setState(() {
      loading = false;
    });
    if (isMinted) {
      final walletIndex = await asset.getOwnerWallet();
      if (walletIndex == null) return;
      final imageData = await imageFile.writeAsBytes(img.encodePng(image));
      final jsonData = await metadataFile.writeAsString(jsonEncode(metadata));
      postcardService
          .stampPostcard(
              tokenId,
              walletIndex.first,
              walletIndex.second,
              imageData,
              jsonData,
              widget.payload.location,
              counter,
              contractAddress)
          .then((value) {
        if (!value) {
          log.info("[POSTCARD] Stamp failed");
        } else {
          postcardService.updateStampingPostcard([
            StampingPostcard(
              indexId: asset.id,
              address: address,
              imagePath: imagePath,
              metadataPath: metadataPath,
              counter: counter,
            )
          ]);
        }
      });
      if (!mounted) return;
      injector<NavigationService>().popUntilHomeOrSettings();
      Navigator.of(context).pushNamed(StampPreview.tag,
          arguments: StampPreviewPayload(
              imagePath: imagePath, metadataPath: metadataPath, asset: asset));
      return;
    } else {
      if (!mounted) return;
      UIHelper.showInfoDialog(context, "toke_minting", "token_minting_desc",
          isDismissible: true, closeButton: "close".tr());
    }
  }
}

class HandSignaturePayload {
  final Uint8List image;
  final AssetToken asset;
  final Position? location;
  final String address;

  HandSignaturePayload(this.image, this.asset, this.location, this.address);
}
