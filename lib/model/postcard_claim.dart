// ignore_for_file: public_member_api_docs, sort_constructors_first

class ClaimPostCardRequest {
  String? claimID;
  String? timestamp;
  String? publicKey;
  String? address;
  String? signature;
  ClaimPostCardRequest({
    this.claimID,
    this.timestamp,
    this.publicKey,
    this.address,
    this.signature,
  });

  ClaimPostCardRequest copyWith({
    String? claimID,
    String? timestamp,
    String? publicKey,
    String? address,
    String? signature,
  }) {
    return ClaimPostCardRequest(
      claimID: claimID ?? this.claimID,
      timestamp: timestamp ?? this.timestamp,
      publicKey: publicKey ?? this.publicKey,
      address: address ?? this.address,
      signature: signature ?? this.signature,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'claimID': claimID,
      'timestamp': timestamp,
      'publicKey': publicKey,
      'address': address,
      'signature': signature,
    };
  }

  factory ClaimPostCardRequest.fromJson(Map<String, dynamic> map) {
    return ClaimPostCardRequest(
      claimID: map['claimID'] != null ? map['claimID'] as String : null,
      timestamp: map['timestamp'] != null ? map['timestamp'] as String : null,
      publicKey: map['publicKey'] != null ? map['publicKey'] as String : null,
      address: map['address'] != null ? map['address'] as String : null,
      signature: map['signature'] != null ? map['signature'] as String : null,
    );
  }

  @override
  String toString() {
    return 'ClaimPostCardRequest(claimID: $claimID, timestamp: $timestamp, publicKey: $publicKey, address: $address, signature: $signature)';
  }

  @override
  bool operator ==(covariant ClaimPostCardRequest other) {
    if (identical(this, other)) return true;

    return other.claimID == claimID &&
        other.timestamp == timestamp &&
        other.publicKey == publicKey &&
        other.address == address &&
        other.signature == signature;
  }

  @override
  int get hashCode {
    return claimID.hashCode ^
        timestamp.hashCode ^
        publicKey.hashCode ^
        address.hashCode ^
        signature.hashCode;
  }
}

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

class RequestPostcardRequest {
  final String id;
  RequestPostcardRequest({
    required this.id,
  });
  // fromJson method
  factory RequestPostcardRequest.fromJson(Map<String, dynamic> json) {
    return RequestPostcardRequest(
      id: json['id'] as String,
    );
  }

  // toJson method
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
    };
  }
}

class RequestPostcardResponse {
  final String claimID;
  final String name;
  // constructor
  RequestPostcardResponse({
    required this.claimID,
    required this.name,
  });
  // fromJson method
  factory RequestPostcardResponse.fromJson(Map<String, dynamic> json) {
    return RequestPostcardResponse(
      claimID: json['claimID'] as String,
      name: json['name'] as String,
    );
  }
  // toJson method
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'claimID': claimID,
      'name': name,
    };
  }
}
