import 'package:autonomy_flutter/util/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class LogoCrypto extends StatelessWidget {
  final CryptoType? cryptoType;
  final double? size;

  const LogoCrypto({super.key, this.cryptoType, this.size});

  @override
  Widget build(BuildContext context) {
    switch (cryptoType) {
      case CryptoType.ETH:
        return SvgPicture.asset(
          'assets/images/ether.svg',
          width: size,
          height: size,
        );
      case CryptoType.XTZ:
        return SvgPicture.asset(
          'assets/images/tez.svg',
          width: size,
          height: size,
        );
      case CryptoType.USDC:
        return SvgPicture.asset(
          'assets/images/usdc.svg',
          width: size,
          height: size,
        );
      default:
        return Container();
    }
  }
}
