import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;

class ExternalLink extends StatelessWidget {
  final String link;
  final Color? color;

  const ExternalLink({Key? key, this.color, required this.link})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          if (link.isValidUrl()) {
            Navigator.of(context)
                .pushNamed(AppRouter.irlWebView, arguments: link);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: SvgPicture.asset(
            "assets/images/external_link.svg",
            width: 20,
            height: 20,
            colorFilter: color == null
                ? null
                : ui.ColorFilter.mode(color!, BlendMode.srcIn),
          ),
        ));
  }
}
