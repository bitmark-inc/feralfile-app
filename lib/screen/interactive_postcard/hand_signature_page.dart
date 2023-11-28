import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
import 'package:autonomy_flutter/util/moma_style_color.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_theme/style/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hand_signature/signature.dart';
import 'package:image/image.dart' as img;
import 'package:nft_collection/models/asset_token.dart';
import 'package:path_provider/path_provider.dart';

class HandSignaturePage extends StatefulWidget {
  static const String handSignaturePage = 'hand_signature_page';
  final HandSignaturePayload payload;

  const HandSignaturePage({required this.payload, super.key});

  @override
  State<HandSignaturePage> createState() => _HandSignaturePageState();
}

class _HandSignaturePageState extends State<HandSignaturePage> {
  bool didDraw = false;
  bool loading = false;
  bool skipping = false;
  Uint8List? resizedStamp;
  final _controller = HandSignatureControl();

  @override
  void initState() {
    super.initState();
    unawaited(resizeStamp());
  }

  Future<void> resizeStamp() async {
    final image = await resizeImage(ResizeImageParams(
        img.decodePng(widget.payload.image)!, STAMP_SIZE, STAMP_SIZE));
    log.info('[POSTCARD] resized image: $image');
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
          padding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
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
                                    'assets/images/sign_here.svg',
                                    fit: BoxFit.scaleDown)),
                          ),
                        ),
                      ),
                      Container(
                        constraints: const BoxConstraints.expand(),
                        color: Colors.transparent,
                        child: HandSignature(
                          width: 9,
                          maxWidth: 9,
                          control: _controller,
                          onPointerDown: () {
                            setState(() {
                              didDraw = true;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
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
                    Flexible(
                      child: PostcardButton(
                        onTap: _handleClearButtonPressed,
                        enabled: !loading,
                        text: 'clear'.tr(),
                        color: AppColor.white,
                        textColor: AppColor.auQuickSilver,
                      ),
                    ),
                    Flexible(
                      child: PostcardButton(
                        onTap: _handleSkipButtonPressed,
                        enabled: !skipping,
                        isProcessing: skipping,
                        text: 'skip'.tr(),
                        color: AppColor.white,
                        textColor: AppColor.auQuickSilver,
                      ),
                    ),
                    Flexible(
                      flex: 3,
                      child: PostcardButton(
                        isProcessing: loading,
                        enabled: !loading && didDraw && resizedStamp != null,
                        onTap: _handleSaveButtonPressed,
                        color: MoMAColors.moMA8,
                        text: 'continue'.tr(),
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
    _controller.clear();
  }

  Future<void> _handleSkipButtonPressed() async {
    setState(() {
      skipping = true;
    });
    try {
      await _saveStampAndContinue(addSignature: false);
    } catch (e) {
      setState(() {
        skipping = false;
      });
      log.info(['[POSTCARD][_handleSkipButtonPressed] [error] [$e ]']);
      rethrow;
    }
  }

  Future<void> _handleSaveButtonPressed() async {
    setState(() {
      loading = true;
    });
    try {
      await _saveStampAndContinue();
    } catch (e) {
      setState(() {
        loading = false;
      });
      log.info(['[POSTCARD][_handleSaveButtonPressed] [error] [$e ]']);
      rethrow;
    }
  }

  Future<File> _writeImageData(
      {required String fileName, bool addSignature = true}) async {
    if (resizedStamp == null) {
      await resizeStamp();
    }
    final dir = (await getApplicationDocumentsDirectory()).path;
    final imagePath = '$dir/$fileName';
    File imageFile = File(imagePath);
    if (addSignature) {
      final data = await _controller.toImage(
          color: Colors.black, background: Colors.transparent);
      log.info(['[POSTCARD][_handleSaveButtonPressed] [data] [$data ]']);
      final signature = img.decodePng(data!.buffer.asUint8List());
      final newHeight = signature!.height * STAMP_SIZE ~/ signature.width;
      final resizedSignature = await resizeImage(
          ResizeImageParams(signature, STAMP_SIZE, newHeight));
      final image = await compositeImage(
          [resizedStamp!, img.encodePng(resizedSignature)]);
      log.info('[POSTCARD][_handleSaveButtonPressed] [image] [$image');
      await imageFile.writeAsBytes(img.encodePng(image));
    } else {
      log.info('[POSTCARD][_handleSkipButtonPressed] ');
      await imageFile.writeAsBytes(resizedStamp!);
    }
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

  Future<void> _saveStampAndContinue({bool addSignature = true}) async {
    setState(() {
      loading = true;
    });
    try {
      final asset = widget.payload.asset;
      final tokenId = asset.tokenId ?? '';
      final counter = asset.numberOwners;
      final contractAddress = Environment.postcardContractAddress;

      final imageDataFilename = '$contractAddress-$tokenId-$counter-image.png';
      final imageDataFile = await _writeImageData(
          fileName: imageDataFilename, addSignature: addSignature);

      setState(() {
        loading = false;
      });
      if (!mounted) {
        return;
      }
      unawaited(Navigator.of(context).popAndPushNamed(
        AppRouter.postcardLocationExplain,
        arguments: PostcardExplainPayload(
          asset,
          PostcardAsyncButton(
            text: 'continue'.tr(),
            fontSize: 18,
            onTap: () async {
              final counter = asset.numberOwners;
              GeoLocation? geoLocation;
              if (counter <= 1) {
                geoLocation = moMAGeoLocation;
              } else {
                geoLocation = await getGeoLocationWithPermission();
              }
              if (geoLocation == null) {
                return;
              }
              final metadataFilename =
                  '$contractAddress-$tokenId-$counter-metadata.json';
              final stampAddress = await geoLocation.position.getAddress();
              final Map<String, dynamic> metadata = {
                'address': stampAddress, // stamp address
                'claimAddress': stampAddress,
                'stampedAt': DateTime.now().toIso8601String()
              };
              final metadataFile = await _writeMetadata(
                  metadata: metadata, fileName: metadataFilename);
              unawaited(injector<NavigationService>().navigateTo(
                  StampPreview.tag,
                  arguments: StampPreviewPayload(
                      imagePath: imageDataFile.path,
                      metadataPath: metadataFile.path,
                      asset: asset,
                      location: geoLocation.position)));
            },
            color: AppColor.momaGreen,
          ),
        ),
      ));
    } catch (e) {
      setState(() {
        loading = false;
      });
      log.info(['[POSTCARD][_handleSaveButtonPressed] [error] [$e ]']);
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
