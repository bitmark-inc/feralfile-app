class DailyToken {
  final DateTime displayTime;
  final String blockchain;
  final String contractAddress;
  final String tokenID;

  DailyToken({
    required this.displayTime,
    required this.blockchain,
    required this.contractAddress,
    required this.tokenID,
  });

  factory DailyToken.fromJson(Map<String, dynamic> json) => DailyToken(
        displayTime: DateTime.parse(json['displayTime']),
        blockchain: json['blockchain'],
        contractAddress: json['contractAddress'],
        tokenID: json['tokenID'],
      );

  Map<String, dynamic> toJson() => {
        'blockchain': blockchain,
        'contractAddress': contractAddress,
        'tokenID': tokenID,
        'displayTime': displayTime.toIso8601String(),
      };
}

extension DailiesTokenExtension on DailyToken {
  String get _blockchainPrefix {
    switch (blockchain.toLowerCase()) {
      case 'bitmark':
        return 'bmk';
      default:
        return blockchain.substring(0, 3).toLowerCase();
    }
  }

  String get indexId {
    final blockchainPrefix = _blockchainPrefix;
    return '$blockchainPrefix-$contractAddress-$tokenID';
  }
}
