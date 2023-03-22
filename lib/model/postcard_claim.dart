class ClaimPostCardResponse {
  String? tokenID;
  String? imageCID;
  String? blockchain;
  String? owner;
  String? contractAddress;
  ClaimPostCardResponse({
    this.tokenID,
    this.imageCID,
    this.blockchain,
    this.owner,
    this.contractAddress,
  });

  ClaimPostCardResponse copyWith({
    String? tokenID,
    String? imageCID,
    String? blockchain,
    String? owner,
    String? contractAddress,
  }) {
    return ClaimPostCardResponse(
      tokenID: tokenID ?? this.tokenID,
      imageCID: imageCID ?? this.imageCID,
      blockchain: blockchain ?? this.blockchain,
      owner: owner ?? this.owner,
      contractAddress: contractAddress ?? this.contractAddress,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tokenID': tokenID,
      'imageCID': imageCID,
      'blockchain': blockchain,
      'owner': owner,
      'contractAddress': contractAddress,
    };
  }

  factory ClaimPostCardResponse.fromJson(Map<String, dynamic> map) {
    return ClaimPostCardResponse(
      tokenID: map['tokenID'] != null ? map['tokenID'] as String : null,
      imageCID: map['imageCID'] != null ? map['imageCID'] as String : null,
      blockchain:
          map['blockchain'] != null ? map['blockchain'] as String : null,
      owner: map['owner'] != null ? map['owner'] as String : null,
      contractAddress: map['contractAddress'] != null
          ? map['contractAddress'] as String
          : null,
    );
  }

  @override
  String toString() {
    return 'ClaimPostCardResponse(tokenID: $tokenID, imageCID: $imageCID, blockchain: $blockchain, owner: $owner, contractAddress: $contractAddress)';
  }

  @override
  bool operator ==(covariant ClaimPostCardResponse other) {
    if (identical(this, other)) return true;

    return other.tokenID == tokenID &&
        other.imageCID == imageCID &&
        other.blockchain == blockchain &&
        other.owner == owner &&
        other.contractAddress == contractAddress;
  }

  @override
  int get hashCode {
    return tokenID.hashCode ^
        imageCID.hashCode ^
        blockchain.hashCode ^
        owner.hashCode ^
        contractAddress.hashCode;
  }
}
