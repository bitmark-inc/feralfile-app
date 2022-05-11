import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:floor/floor.dart';

@Entity(tableName: 'Provenance', foreignKeys: [
  ForeignKey(
    childColumns: ['tokenID'],
    parentColumns: ['id'],
    entity: AssetToken,
    onDelete: ForeignKeyAction.cascade,
  )
], indices: [
  Index(value: ['tokenID'])
])
class Provenance {
  @primaryKey
  String txID;
  String type;
  String blockchain;
  String owner;
  DateTime timestamp;
  String txURL;
  String tokenID;

  Provenance({
    required this.type,
    required this.blockchain,
    required this.txID,
    required this.owner,
    required this.timestamp,
    required this.txURL,
    required this.tokenID,
  });

  factory Provenance.fromJson(Map<String, dynamic> json, String tokenID) =>
      Provenance(
        type: json['type'] as String,
        blockchain: json['blockchain'] as String,
        txID: json['txid'] as String,
        owner: json['owner'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        txURL: (json['txURL'] as String?) ?? '',
        tokenID: tokenID,
      );
}
