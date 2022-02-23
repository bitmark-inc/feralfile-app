class TezosConnection {
  TezosConnection({
    required this.address,
    required this.peer,
    required this.permissionResponse,
  });

  String address;
  Peer peer;
  PermissionResponse permissionResponse;

  factory TezosConnection.fromJson(Map<String, dynamic> json) => TezosConnection(
    address: json["address"],
    peer: Peer.fromJson(json["peer"]),
    permissionResponse: PermissionResponse.fromJson(json["permissionResponse"]),
  );

  Map<String, dynamic> toJson() => {
    "address": address,
    "peer": peer.toJson(),
    "permissionResponse": permissionResponse.toJson(),
  };
}

class Peer {
  Peer({
    required this.relayServer,
    required this.id,
    required this.kind,
    required this.publicKey,
    required this.name,
    required this.version,
  });

  String relayServer;
  String id;
  String kind;
  String publicKey;
  String name;
  String version;

  factory Peer.fromJson(Map<String, dynamic> json) => Peer(
    relayServer: json["relayServer"],
    id: json["id"],
    kind: json["kind"],
    publicKey: json["publicKey"],
    name: json["name"],
    version: json["version"],
  );

  Map<String, dynamic> toJson() => {
    "relayServer": relayServer,
    "id": id,
    "kind": kind,
    "publicKey": publicKey,
    "name": name,
    "version": version,
  };
}

class PermissionResponse {
  PermissionResponse({
    required this.scopes,
    required this.blockchainIdentifier,
    required this.id,
    required this.requestOrigin,
    required this.version,
    required this.publicKey,
    required this.network,
  });

  List<String> scopes;
  String blockchainIdentifier;
  String id;
  RequestOrigin requestOrigin;
  String version;
  String publicKey;
  TezosNetwork network;

  factory PermissionResponse.fromJson(Map<String, dynamic> json) => PermissionResponse(
    scopes: List<String>.from(json["scopes"].map((x) => x)),
    blockchainIdentifier: json["blockchainIdentifier"],
    id: json["id"],
    requestOrigin: RequestOrigin.fromJson(json["requestOrigin"]),
    version: json["version"],
    publicKey: json["publicKey"],
    network: TezosNetwork.fromJson(json["network"]),
  );

  Map<String, dynamic> toJson() => {
    "scopes": List<dynamic>.from(scopes.map((x) => x)),
    "blockchainIdentifier": blockchainIdentifier,
    "id": id,
    "requestOrigin": requestOrigin.toJson(),
    "version": version,
    "publicKey": publicKey,
    "network": network.toJson(),
  };
}

class TezosNetwork {
  TezosNetwork({
    required this.type,
  });

  String type;

  factory TezosNetwork.fromJson(Map<String, dynamic> json) => TezosNetwork(
    type: json["type"],
  );

  Map<String, dynamic> toJson() => {
    "type": type,
  };
}

class RequestOrigin {
  RequestOrigin({
    required this.kind,
    required this.id,
  });

  String kind;
  String id;

  factory RequestOrigin.fromJson(Map<String, dynamic> json) => RequestOrigin(
    kind: json["kind"],
    id: json["id"],
  );

  Map<String, dynamic> toJson() => {
    "kind": kind,
    "id": id,
  };
}
