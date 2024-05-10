class AccountV2Request {
  final IdentityType type;
  final String requester;
  final String? publicKey;
  final String timestamp;
  final String signature;

  AccountV2Request({
    required this.type,
    required this.requester,
    required this.timestamp,
    required this.signature,
    this.publicKey,
  });

  // toJson
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.toString(),
        'requester': requester,
        'publicKey': publicKey,
        'timestamp': timestamp,
        'signature': signature,
      };
}

enum IdentityType {
  ethereum,
  tezos,
  did,
}
