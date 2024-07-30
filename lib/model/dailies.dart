import 'package:autonomy_flutter/util/string_ext.dart';

class DailyToken {
  final DateTime displayTime;
  final String blockchain;
  final String contractAddress;
  final String artworkID;

  DailyToken({
    required this.displayTime,
    required this.blockchain,
    required this.contractAddress,
    required this.artworkID,
  });

  factory DailyToken.fromJson(Map<String, dynamic> json) => DailyToken(
        displayTime: DateTime.parse(json['displayTime']),
        blockchain: json['blockchain'],
        contractAddress: json['contractAddress'],
        artworkID: json['artworkID'],
      );

  Map<String, dynamic> toJson() => {
        'blockchain': blockchain,
        'contractAddress': contractAddress,
        'artworkID': artworkID,
        'displayTime': displayTime.toIso8601String(),
      };
}

extension DailiesTokenExtension on DailyToken {
  String get indexId {
    final blockchainPrefix = blockchain.substring(0, 3).toLowerCase();
    // if artworkID is a hex string, convert it to decimal
    final tokenId = artworkID.isDecimal ? artworkID : artworkID.hexToDecimal;
    return '$blockchainPrefix-$contractAddress-$tokenId';
  }
}
