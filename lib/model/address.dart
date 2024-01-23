import 'package:autonomy_flutter/util/constants.dart';

class Address {
  String address;
  CryptoType type;
  String? domain;

  Address({required this.address, required this.type, this.domain});

  // copyWith
  Address copyWith({String? address, CryptoType? type, String? domain}) =>
      Address(
        address: address ?? this.address,
        type: type ?? this.type,
        domain: domain ?? this.domain,
      );
}
