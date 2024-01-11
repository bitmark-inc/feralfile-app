class FFUser {
  final String id;
  final String? slug;
  final String alias;
  final String? avatarURI;
  final String? fullName;
  String? type;
  Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FFUser({
    required this.id,
    required this.alias,
    this.slug,
    this.avatarURI,
    this.fullName,
    this.type,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });
}

class FFArtist {
  final String id;
  final String alias;
  final String slug;
  final bool? verified;
  final bool? isArtist;
  final String? fullName;
  final String? avatarURI;
  final String? accountNumber;
  final String? type;

  FFArtist(
    this.id,
    this.alias,
    this.slug,
    this.verified,
    this.isArtist,
    this.fullName,
    this.avatarURI,
    this.accountNumber,
    this.type,
  );

  factory FFArtist.fromJson(Map<String, dynamic> json) => FFArtist(
        json['ID'] as String,
        json['alias'] as String,
        json['slug'] as String,
        json['verified'] as bool?,
        json['isArtist'] as bool?,
        json['fullName'] as String?,
        json['avatarURI'] as String?,
        json['accountNumber'] as String?,
        json['type'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'ID': id,
        'alias': alias,
        'slug': slug,
        'verified': verified,
        'isArtist': isArtist,
        'fullName': fullName,
        'avatarURI': avatarURI,
        'accountNumber': accountNumber,
        'type': type,
      };
}

class FFCurator extends FFUser {
  final String? email;
  final String avatarUri;

  FFCurator({
    required super.id,
    required super.alias,
    required String super.slug,
    required this.avatarUri,
    this.email,
    super.fullName,
    super.type,
    super.metadata,
    super.createdAt,
    super.updatedAt,
  });

  factory FFCurator.fromJson(Map<String, dynamic> json) => FFCurator(
        id: json['ID'],
        alias: json['alias'],
        slug: json['slug'],
        email: json['email'],
        avatarUri: json['avatarURI'],
        fullName: json['fullName'],
        type: json['type'],
        metadata: json['metadata'],
        createdAt: DateTime.tryParse(json['createdAt']),
        updatedAt: DateTime.tryParse(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
        'ID': id,
        'alias': alias,
        'slug': slug,
        'email': email,
        'avatarURI': avatarURI,
        'fullName': fullName,
        'type': type,
        'metadata': metadata,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
