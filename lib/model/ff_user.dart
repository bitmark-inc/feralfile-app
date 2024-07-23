class FFUser {
  final String id;
  final AlumniAccount? alumniAccount;
  String? type;
  Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FFUser({
    required this.id,
    this.alumniAccount,
    this.type,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });
}

class AlumniAccount {
  final String? alias;
  final String? slug;
  final String? avatarURI;
  final String? fullName;

  AlumniAccount({
    this.alias,
    this.slug,
    this.avatarURI,
    this.fullName,
  });

  factory AlumniAccount.fromJson(Map<String, dynamic> json) => AlumniAccount(
        alias: json['alias'] as String?,
        slug: json['slug'] as String?,
        avatarURI: json['avatarURI'] as String?,
        fullName: json['fullName'] as String?,
      );
  Map<String, dynamic> toJson() => {
        'alias': alias,
        'slug': slug,
        'avatarURI': avatarURI,
        'fullName': fullName,
      };
}

class FFArtist {
  final String id;
  final bool? verified;
  final String? accountNumber;
  final String? type;
  final AlumniAccount? alumniAccount;

  FFArtist(
    this.id,
    this.verified,
    this.accountNumber,
    this.type,
    this.alumniAccount,
  );

  factory FFArtist.fromJson(Map<String, dynamic> json) => FFArtist(
      json['ID'] as String,
      json['verified'] as bool?,
      json['accountNumber'] as String?,
      json['type'] as String?,
      json['alumniAccount'] != null
          ? AlumniAccount.fromJson(
              json['alumniAccount'] as Map<String, dynamic>)
          : null);

  Map<String, dynamic> toJson() => {
        'ID': id,
        'verified': verified,
        'accountNumber': accountNumber,
        'type': type,
        'alumniAccount': alumniAccount?.toJson(),
      };
}

class FFCurator extends FFUser {
  final String? email;

  FFCurator({
    required super.id,
    this.email,
    super.type,
    super.metadata,
    super.createdAt,
    super.updatedAt,
    super.alumniAccount,
  });

  factory FFCurator.fromJson(Map<String, dynamic> json) => FFCurator(
        id: json['ID'],
        email: json['email'] as String?,
        type: json['type'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'])
            : null,
        alumniAccount: json['alumniAccount'] != null
            ? AlumniAccount.fromJson(
                json['alumniAccount'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'ID': id,
        'email': email,
        'type': type,
        'metadata': metadata,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'alumniAccount': alumniAccount?.toJson(),
      };
}
