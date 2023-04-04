
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:floor/floor.dart';

@entity
class WalletAddress {
  @primaryKey
  final String address;
  @ForeignKey(
      childColumns: ['uuid'],
      parentColumns: ['uuid'],
      entity: Persona,
      onDelete: ForeignKeyAction.cascade)
  final String uuid;
  final int index;
  final String cryptoType;
  final DateTime createdAt;
  final bool isHidden;

  WalletAddress(
      {required this.address,
      required this.uuid,
      required this.index,
      required this.cryptoType,
      required this.createdAt,
      this.isHidden = false});
}