import 'package:floor/floor.dart';
import 'package:nft_collection/models/address_index.dart';

@entity
class WalletAddress {
  @primaryKey
  final String address;
  final String uuid;
  final int index;
  final String cryptoType;
  final DateTime createdAt;
  final bool isHidden;
  final String? name;
  final int? accountOrder;

  WalletAddress(
      {required this.address,
      required this.uuid,
      required this.index,
      required this.cryptoType,
      required this.createdAt,
      this.isHidden = false,
      this.name,
      this.accountOrder});

  WalletAddress copyWith({
    String? address,
    String? uuid,
    int? index,
    String? cryptoType,
    DateTime? createdAt,
    bool? isHidden,
    String? name,
    int? accountOrder,
  }) =>
      WalletAddress(
        address: address ?? this.address,
        uuid: uuid ?? this.uuid,
        index: index ?? this.index,
        cryptoType: cryptoType ?? this.cryptoType,
        createdAt: createdAt ?? this.createdAt,
        isHidden: isHidden ?? this.isHidden,
        name: name ?? this.name,
        accountOrder: accountOrder ?? this.accountOrder,
      );

  AddressIndex get addressIndex =>
      AddressIndex(address: address, createdAt: createdAt);
}
