import 'dart:ui';

import 'package:autonomy_flutter/screen/interactive_postcard/stamp_preview.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_theme/style/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:image/image.dart' as img;

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
                        minimumStrokeWidth: 12,
                        maximumStrokeWidth: 35,
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
              const SizedBox(height: 15),
              Row(
                children: [
                  IconButton(
                    padding: const EdgeInsets.all(0),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    color: Colors.blue,
                    alignment: Alignment.centerLeft,
                    icon: SvgPicture.asset(
                      'assets/images/icon_back.svg',
                      color: AppColor.white,
                    ),
                  ),
                  Expanded(
                    child: OutlineButton(
                      onTap: _handleClearButtonPressed,
                      text: "start_over".tr(),
                      color: Colors.transparent,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: PrimaryButton(
                      isProcessing: loading,
                      enabled: didDraw,
                      onTap: _handleSaveButtonPressed,
                      text: "sign_postcard".tr(),
                    ),
                  ),
                ],
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
    UIHelper.showLoadingScreen(context, text: "loading...".tr());
    final stampWidth = MediaQuery.of(context).size.width.toInt();
    final signatureWith = MediaQuery.of(context).size.height.toInt() - 65;
    final ratio = signatureWith.toDouble() / stampWidth.toDouble();
    final data =
        await signatureGlobalKey.currentState!.toImage(pixelRatio: ratio * 1.5);
    final bytes = await data.toByteData(format: ImageByteFormat.png);

    final image = await compositeImage(
        [widget.payload.image, bytes!.buffer.asUint8List()]);
    if (!mounted) return;
    UIHelper.hideInfoDialog(context);
    Navigator.of(context).pushNamed(StampPreview.tag,
        arguments: StampPreviewPayload(
          image,
        ));
  }

}

class HandSignaturePayload {
  final Uint8List image;

  HandSignaturePayload(this.image);
}

Future<img.Image> compositeImage(List<Uint8List> images) async {
  return await compute(compositeImages, images);
}

img.Image compositeImages(List<Uint8List> images) {
  return img.compositeImage(
      img.decodePng(images.first)!, img.decodePng(images.last)!,
      center: true);
}
