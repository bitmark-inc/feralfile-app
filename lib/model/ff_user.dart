class FFUser {
  final String id;
  final AlumniAccount? alumniAccount;
  String? type;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FFUser({
    required this.id,
    this.alumniAccount,
    this.type,
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

class FFArtist extends FFUser {
  FFArtist({
    required super.id,
    super.type,
    super.createdAt,
    super.updatedAt,
    super.alumniAccount,
  });

  factory FFArtist.fromJson(Map<String, dynamic> json) => FFArtist(
      id: json['ID'] as String,
      type: json['type'] as String?,
      alumniAccount: json['alumniAccount'] != null
          ? AlumniAccount.fromJson(
              json['alumniAccount'] as Map<String, dynamic>)
          : null);

  Map<String, dynamic> toJson() => {
        'ID': id,
        'type': type,
        'alumniAccount': alumniAccount?.toJson(),
      };
}

class FFCurator extends FFUser {
  FFCurator({
    required super.id,
    super.type,
    super.createdAt,
    super.updatedAt,
    super.alumniAccount,
  });

  factory FFCurator.fromJson(Map<String, dynamic> json) => FFCurator(
        id: json['ID'],
        type: json['type'] as String?,
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
        'type': type,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'alumniAccount': alumniAccount?.toJson(),
      };
}
