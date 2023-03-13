import 'dart:typed_data';
import 'dart:ui';

import 'package:autonomy_flutter/screen/interactive_postcard/stamp_preview.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_theme/style/colors.dart';
import 'package:easy_localization/easy_localization.dart';
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
                        minimumStrokeWidth: 5,
                        maximumStrokeWidth: 10,
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
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: PrimaryButton(
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
    final data =
        await signatureGlobalKey.currentState!.toImage(pixelRatio: 2.0);
    final bytes = await data.toByteData(format: ImageByteFormat.png);
    if (!mounted) return;
    final signature = bytes!.buffer.asUint8List();
    final image = img.compositeImage(
        img.decodePng(widget.payload.image)!, img.decodePng(signature)!,
        center: true);
    Navigator.of(context).pushNamed(StampPreview.tag,
        arguments: HandSignaturePayload(
          img.encodePng(image),
        ));
  }
}

class HandSignaturePayload {
  final Uint8List image;

  HandSignaturePayload(this.image);
}
