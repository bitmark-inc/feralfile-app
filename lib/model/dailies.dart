import 'package:autonomy_flutter/model/ff_artwork.dart';

class DailyToken {
  DailyToken({
    required this.displayTime,
    required this.blockchain,
    required this.contractAddress,
    required this.tokenID,
    this.dailyNote,
    this.artwork,
  });

  factory DailyToken.fromJson(Map<String, dynamic> json) => DailyToken(
        displayTime: DateTime.parse(json['displayTime'] as String),
        blockchain: json['blockchain'] as String,
        contractAddress: json['contractAddress'] as String,
        tokenID: json['tokenID'] as String,
        dailyNote: json['note'] as String?,
        artwork: json['artwork'] != null
            ? Artwork.fromJson(
                Map<String, dynamic>.from(json['artwork'] as Map))
            : null,
      );
  final DateTime displayTime;
  final String blockchain;
  final String contractAddress;
  final String tokenID;
  final String? dailyNote;
  final Artwork? artwork;

  Map<String, dynamic> toJson() => {
        'blockchain': blockchain,
        'contractAddress': contractAddress,
        'tokenID': tokenID,
        'displayTime': displayTime.toIso8601String(),
        'note': dailyNote,
        'artwork': artwork?.toJson(),
      };
}

extension DailiesTokenExtension on DailyToken {
  String _blockchainPrefix(String blockchain) {
    switch (blockchain.toLowerCase()) {
      case 'bitmark':
        return 'bmk';
      default:
        return blockchain.substring(0, 3).toLowerCase();
    }
  }

  String _convertToIndexId(
    String blockchain,
    String contractAddress,
    String tokenID,
  ) {
    final blockchainPrefix = _blockchainPrefix(blockchain);
    return '$blockchainPrefix-$contractAddress-$tokenID';
  }

  String get indexId {
    final swap = artwork?.swap;
    if (swap != null) {
      return _convertToIndexId(
        swap.blockchainType,
        swap.contractAddress,
        swap.token!,
      );
    } else {
      return _convertToIndexId(blockchain, contractAddress, tokenID);
    }
  }

  String get artworkId {
    final swap = artwork?.swap;
    if (swap != null) {
      return swap.token!;
    } else {
      return tokenID;
    }
  }
}
