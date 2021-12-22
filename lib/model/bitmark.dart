class Bitmark {
  Bitmark({
    required this.headId,
    required this.owner,
    required this.assetId,
    required this.id,
    required this.issuer,
    required this.issuedAt,
    required this.edition,
    required this.head,
    required this.status,
    required this.blockNumber,
    required this.issueBlockNumber,
    required this.issueBlockOffset,
    required this.offset,
    required this.createdAt,
    required this.confirmedAt,
    this.provenance,
  });

  String headId;
  String owner;
  String assetId;
  String id;
  String issuer;
  DateTime issuedAt;
  int edition;
  String head;
  String status;
  int blockNumber;
  int issueBlockNumber;
  int issueBlockOffset;
  int offset;
  DateTime createdAt;
  DateTime confirmedAt;
  List<Provenance>? provenance;

  factory Bitmark.fromJson(Map<String, dynamic> json) => Bitmark(
    headId: json["head_id"],
    owner: json["owner"],
    assetId: json["asset_id"],
    id: json["id"],
    issuer: json["issuer"],
    issuedAt: DateTime.parse(json["issued_at"]),
    edition: json["edition"],
    head: json["head"],
    status: json["status"],
    blockNumber: json["block_number"],
    issueBlockNumber: json["issue_block_number"],
    issueBlockOffset: json["issue_block_offset"],
    offset: json["offset"],
    createdAt: DateTime.parse(json["created_at"]),
    confirmedAt: DateTime.parse(json["confirmed_at"]),
    provenance: json["provenance"] != null ? List<Provenance>.from(json["provenance"].map((x) => Provenance.fromJson(x))) : null,
  );

  Map<String, dynamic> toJson() => {
    "head_id": headId,
    "owner": owner,
    "asset_id": assetId,
    "id": id,
    "issuer": issuer,
    "issued_at": issuedAt.toIso8601String(),
    "edition": edition,
    "head": head,
    "status": status,
    "block_number": blockNumber,
    "issue_block_number": issueBlockNumber,
    "issue_block_offset": issueBlockOffset,
    "offset": offset,
    "created_at": createdAt.toIso8601String(),
    "confirmed_at": confirmedAt.toIso8601String(),
    "provenance": provenance != null ? List<dynamic>.from(provenance!.map((x) => x.toJson())) : [],
  };
}

class Provenance {
  Provenance({
    required this.txId,
    required this.owner,
    required this.status,
    required this.createdAt,
  });

  String txId;
  String owner;
  String status;
  DateTime createdAt;

  factory Provenance.fromJson(Map<String, dynamic> json) => Provenance(
    txId: json["tx_id"],
    owner: json["owner"],
    status: json["status"],
    createdAt: DateTime.parse(json["created_at"]),
  );

  Map<String, dynamic> toJson() => {
    "tx_id": txId,
    "owner": owner,
    "status": status,
    "created_at": createdAt.toIso8601String(),
  };
}
