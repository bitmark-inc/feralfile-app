import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Default of error state widget
class NFTErrorWidget extends StatelessWidget {
  const NFTErrorWidget({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: SvgPicture.asset(
          'assets/images/image_error.svg',
          width: 148,
          height: 158,
        ),
      );
}
