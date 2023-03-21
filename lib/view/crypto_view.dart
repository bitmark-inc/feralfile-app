

import 'package:autonomy_flutter/util/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';

class LogoCrypto extends StatelessWidget {
  final CryptoType? cryptoType;
  final double? size;

  const LogoCrypto({Key? key, this.cryptoType, this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (cryptoType == CryptoType.XTZ) {
      return SvgPicture.asset(
        "assets/images/tez.svg",
        width: size,
        height: size,
      );
    }
    if (cryptoType == CryptoType.ETH) {
      return SvgPicture.asset(
        'assets/images/ether.svg',
        width: size,
        height: size,
      );
    }
    return Container();
  }
}