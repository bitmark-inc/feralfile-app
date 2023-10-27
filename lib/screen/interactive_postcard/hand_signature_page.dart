import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_explain.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/stamp_preview.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/geolocation.dart';
import 'package:autonomy_flutter/util/isolate.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_theme/style/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
    final image = await resizeImage(ResizeImageParams(
        img.decodePng(widget.payload.image)!, STAMP_SIZE, STAMP_SIZE));
    log.info('[POSTCARD] resized image: ${image.toString()}');
    setState(() {
      resizedStamp = img.encodePng(image);
    });
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = AppColor.chatPrimaryColor;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: getLightEmptyAppBar(backgroundColor),
      body: RotatedBox(
        quarterTurns: -1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
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
                      Positioned.fill(
                        child: Container(
                          color: AppColor.white.withOpacity(0.3),
                          child: Visibility(
                            visible: !didDraw,
                            child: Align(
                                child: SvgPicture.asset(
                                    "assets/images/sign_here.svg",
                                    fit: BoxFit.scaleDown)),
                          ),
                        ),
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
                        colorFilter: const ColorFilter.mode(
                            AppColor.white, BlendMode.srcIn),
                      ),
                    ),
                    Expanded(
                      child: PostcardButton(
                        onTap: _handleClearButtonPressed,
                        enabled: !loading,
                        text: "clear".tr(),
                        color: AppColor.white,
                        textColor: AppColor.auQuickSilver,
                      ),
                    ),
                    Expanded(
                      child: PostcardButton(
                        isProcessing: loading,
                        enabled: !loading && didDraw && resizedStamp != null,
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

  Future<File> _writeImageData(
      {required ui.Image data, required String fileName}) async {
    final data = await signatureGlobalKey.currentState!.toImage();
    log.info(
        ['[POSTCARD][_handleSaveButtonPressed] [data] [${data.toString()} ]']);
    final bytes = await data.toByteData(format: ImageByteFormat.png);
    final signature = img.decodePng(bytes!.buffer.asUint8List());
    final newHeight = signature!.height * STAMP_SIZE ~/ signature.width;
    final resizedSignature =
        await resizeImage(ResizeImageParams(signature, STAMP_SIZE, newHeight));
    if (resizedStamp == null) {
      await resizeStamp();
    }
    final image =
        await compositeImage([resizedStamp!, img.encodePng(resizedSignature)]);
    log.info(
        '[POSTCARD][_handleSaveButtonPressed] [image] [${image.toString()}');
    final dir = (await getApplicationDocumentsDirectory()).path;
    final imagePath = '$dir/$fileName';
    File imageFile = File(imagePath);
    await imageFile.writeAsBytes(img.encodePng(image));
    return imageFile;
  }

  Future<File> _writeMetadata(
      {required Map<String, dynamic> metadata,
      required String fileName}) async {
    final dir = (await getApplicationDocumentsDirectory()).path;
    final metadataPath = '$dir/$fileName';
    File metadataFile = File(metadataPath);
    await metadataFile.writeAsString(jsonEncode(metadata));
    return metadataFile;
  }

  void _handleSaveButtonPressed() async {
    setState(() {
      loading = true;
    });
    try {
      final asset = widget.payload.asset;
      final tokenId = asset.tokenId ?? "";
      final counter = asset.numberOwners;
      final contractAddress = Environment.postcardContractAddress;

      final imageDataFilename = '$contractAddress-$tokenId-$counter-image.png';
      final imageData = await signatureGlobalKey.currentState!.toImage();
      final imageDataFile =
          await _writeImageData(data: imageData, fileName: imageDataFilename);

      setState(() {
        loading = false;
      });
      if (!mounted) return;
      Navigator.of(context).popAndPushNamed(
        AppRouter.postcardLocationExplain,
        arguments: PostcardExplainPayload(
          asset,
          PostcardAsyncButton(
            text: "continue".tr(),
            fontSize: 18,
            onTap: () async {
              final counter = asset.numberOwners;
              GeoLocation? geoLocation = await getGeoLocationWithPermission();
              if (geoLocation == null) return;
              final metadataFilename =
                  '$contractAddress-$tokenId-$counter-metadata.json';
              final stampAddress = await geoLocation.position.getAddress();
              final Map<String, dynamic> metadata = {
                "address": stampAddress, // stamp address
                "claimAddress": stampAddress,
                "stampedAt": DateTime.now().toIso8601String()
              };
              final metadataFile = await _writeMetadata(
                  metadata: metadata, fileName: metadataFilename);
              injector<NavigationService>().navigateTo(StampPreview.tag,
                  arguments: StampPreviewPayload(
                      imagePath: imageDataFile.path,
                      metadataPath: metadataFile.path,
                      asset: asset,
                      location: geoLocation.position));
            },
            color: AppColor.momaGreen,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        loading = false;
      });
      log.info(
          ['[POSTCARD][_handleSaveButtonPressed] [error] [${e.toString()} ]']);
      rethrow;
    }
  }
}

class HandSignaturePayload {
  final Uint8List image;
  final AssetToken asset;

  HandSignaturePayload(
    this.image,
    this.asset,
  );
}
