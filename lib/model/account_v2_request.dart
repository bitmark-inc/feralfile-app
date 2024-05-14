class AccountV2Request {
  final String type;
  final String requester;
  final String? publicKey;
  final String timestamp;
  final String signature;
  final dynamic receipt;

  AccountV2Request({
    required this.type,
    required this.requester,
    required this.timestamp,
    required this.signature,
    this.publicKey,
    this.receipt,
  });

  // toJson
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'requester': requester,
        'publicKey': publicKey,
        'timestamp': timestamp,
        'signature': signature,
        'receipt': receipt,
      };
}
