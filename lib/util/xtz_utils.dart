import 'dart:typed_data';

import 'package:tezart/src/crypto/crypto.dart' as crypto;

class XtzAmountFormatter {
  final int amount;
  XtzAmountFormatter(this.amount);

  String format() {
    return "${amount / 1000000}";
  }
}

const crypto.Prefixes _addressPrefix = crypto.Prefixes.tz1;

String xtzAddress(List<int> publicKey) => crypto.catchUnhandledErrors(() {
      final publicKeyBytes = Uint8List.fromList(publicKey);
      final hash = crypto.hashWithDigestSize(
        size: 160,
        bytes: publicKeyBytes,
      );

      return crypto.encodeWithPrefix(
        prefix: _addressPrefix,
        bytes: hash,
      );
    });
