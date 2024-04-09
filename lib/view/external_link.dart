import 'dart:ui' as ui;

import 'package:autonomy_flutter/util/feral_file_custom_tab.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ExternalLink extends StatelessWidget {
  final String? link;
  final Color? color;
  final Color? disableColor;

  const ExternalLink({super.key, this.color, this.link, this.disableColor});

  @override
  Widget build(BuildContext context) {
    final isValid = link?.isValidUrl() ?? false;
    final colorFilterWhenValid =
        color == null ? null : ui.ColorFilter.mode(color!, BlendMode.srcIn);
    final colorFilterWhenInvalid = disableColor == null
        ? null
        : ui.ColorFilter.mode(disableColor!, BlendMode.srcIn);
    return GestureDetector(
        onTap: () async {
          if (isValid) {
            final browser = FeralFileBrowser();
            await browser.openUrl(link!);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: SvgPicture.asset(
            'assets/images/external_link.svg',
            width: 20,
            height: 20,
            colorFilter:
                isValid ? colorFilterWhenValid : colorFilterWhenInvalid,
          ),
        ));
  }
}
