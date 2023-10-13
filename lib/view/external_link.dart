import 'dart:ui' as ui;

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/irl_screen/webview_irl_screen.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' '';

class ExternalLink extends StatelessWidget {
  final String? link;
  final Color? color;
  final Color? disableColor;

  const ExternalLink({Key? key, this.color, this.link, this.disableColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isValid = link?.isValidUrl() ?? false;
    final colorFilterWhenValid =
        color == null ? null : ui.ColorFilter.mode(color!, BlendMode.srcIn);
    final colorFilterWhenInvalid = disableColor == null
        ? null
        : ui.ColorFilter.mode(disableColor!, BlendMode.srcIn);
    return GestureDetector(
        onTap: () {
          if (isValid) {
            Navigator.of(context).pushNamed(AppRouter.irlWebView,
                arguments: IRLWebScreenPayload(link!));
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: SvgPicture.asset(
            "assets/images/external_link.svg",
            width: 20,
            height: 20,
            colorFilter:
                isValid ? colorFilterWhenValid : colorFilterWhenInvalid,
          ),
        ));
  }
}
