import 'package:autonomy_flutter/model/ff_artwork.dart';

class DailyToken {
  final DateTime displayTime;
  final String blockchain;
  final String contractAddress;
  final String tokenID;
  final String? dailyNote;
  final Artwork? artwork;

  DailyToken({
    required this.displayTime,
    required this.blockchain,
    required this.contractAddress,
    required this.tokenID,
    this.dailyNote,
    this.artwork,
  });

  factory DailyToken.fromJson(Map<String, dynamic> json) => DailyToken(
        displayTime: DateTime.parse(json['displayTime']),
        blockchain: json['blockchain'],
        contractAddress: json['contractAddress'],
        tokenID: json['tokenID'],
        dailyNote: json['note'],
        artwork: json['artwork'] != null
            ? Artwork.fromJson(json['artwork'] as Map<String, dynamic>)
            : null,
      );

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
      String blockchain, String contractAddress, String tokenID) {
    final blockchainPrefix = _blockchainPrefix(blockchain);
    return '$blockchainPrefix-$contractAddress-$tokenID';
  }

  String get indexId {
    return 'eth-0x1d5bdC75918600541C115b74b81a404C9E4AF7D4-29675870761587803123850255772014231519473951568011717151584536753918684144709';
    final swap = artwork?.swap;
    if (swap != null) {
      return _convertToIndexId(
          swap.blockchainType, swap.contractAddress, swap.token!);
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
