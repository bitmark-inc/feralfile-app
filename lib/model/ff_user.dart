class FFUser {
  final String id;
  final String? slug;
  final String alias;
  final String? avatarURI;
  final String? bio;
  final String? fullName;
  final bool? isArtist;
  final bool? isCurator;
  String? type;
  Map<String, dynamic>? metadata;
  List<FFUserDetails> linkedAccounts;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? verified;
  final String? accountNumber;

  FFUser({
    required this.id,
    required this.alias,
    required this.linkedAccounts,
    this.slug,
    this.avatarURI,
    this.bio,
    this.fullName,
    this.isArtist,
    this.isCurator,
    this.type,
    this.metadata,
    this.createdAt,
    this.updatedAt,
    this.verified,
    this.accountNumber,
  });

  // fromJSon
  factory FFUser.fromJson(Map<String, dynamic> json) => FFUser(
        id: json['ID'],
        alias: json['alias'],
        slug: json['slug'],
        avatarURI: json['avatarURI'],
        bio: json['bio'],
        fullName: json['fullName'],
        isArtist: json['isArtist'] as bool?,
        isCurator: json['isCurator'] as bool?,
        type: json['type'],
        metadata: json['metadata'],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'])
            : null,
        linkedAccounts: (json['linkedAccounts'] as List?)
                ?.map((e) => FFUserDetails.fromJson(e))
                .toList() ??
            [],
        verified: json['verified'] as bool?,
        accountNumber: json['accountNumber'] as String?,
      );

  // toJson
  Map<String, dynamic> toJson() => {
        'ID': id,
        'alias': alias,
        'slug': slug,
        'avatarURI': avatarURI,
        'bio': bio,
        'fullName': fullName,
        'isArtist': isArtist,
        'isCurator': isCurator,
        'type': type,
        'metadata': metadata,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'linkedAccounts': linkedAccounts.map((e) => e.toJson()).toList(),
        'verified': verified,
        'accountNumber': accountNumber,
      };
}

class FFUserDetails extends FFUser {
  final String? location;
  final String? website;

  // final VaultAddress? vaultAddresses;
  final List<FFUserDetails>? childs;

  FFUserDetails({
    required super.id,
    required super.alias,
    required super.metadata,
    required super.linkedAccounts,
    super.slug,
    super.avatarURI,
    super.bio,
    super.fullName,
    super.isArtist,
    super.isCurator,
    super.type,
    super.createdAt,
    super.updatedAt,
    super.verified,
    super.accountNumber,
    this.location,
    this.website,
    // this.vaultAddresses,
    this.childs,
  });

  // fromJSon
  factory FFUserDetails.fromJson(Map<String, dynamic> json) => FFUserDetails(
        id: json['ID'],
        alias: json['alias'],
        slug: json['slug'],
        avatarURI: json['avatarURI'],
        bio: json['bio'],
        fullName: json['fullName'],
        isArtist: json['isArtist'] as bool?,
        isCurator: json['isCurator'] as bool?,
        type: json['type'],
        metadata: json['metadata'],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'])
            : null,
        linkedAccounts: (json['linkedAccounts'] as List?)
                ?.map((e) => FFUserDetails.fromJson(e))
                .toList() ??
            [],
        verified: json['verified'] as bool?,
        accountNumber: json['accountNumber'] as String?,
        location: json['location'] as String?,
        website: json['website'] as String?,
        // vaultAddresses: json['vaultAddresses'] != null
        //     ? VaultAddress.fromJson(json['vaultAddresses'])
        //     : null,
        childs: (json['childs'] as List?)
            ?.map((e) => FFUserDetails.fromJson(e))
            .toList(),
      );

  // toJson
  Map<String, dynamic> toJson() => {
        'ID': id,
        'alias': alias,
        'slug': slug,
        'avatarURI': avatarURI,
        'bio': bio,
        'fullName': fullName,
        'isArtist': isArtist,
        'isCurator': isCurator,
        'type': type,
        'metadata': metadata,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'linkedAccounts': linkedAccounts.map((e) => e.toJson()).toList(),
        'verified': verified,
        'accountNumber': accountNumber,
        'location': location,
        'website': website,
        // 'vaultAddresses': vaultAddresses?.toJson(),
        'childs': childs?.map((e) => e.toJson()).toList(),
      };
}

class FFArtist extends FFUserDetails {
  final String? email;

  FFArtist({
    required super.id,
    required super.alias,
    required super.linkedAccounts,
    super.slug,
    super.verified,
    super.fullName,
    super.isArtist,
    super.isCurator,
    super.avatarURI,
    super.bio,
    super.accountNumber,
    super.type,
    this.email,
    super.location,
    super.website,
    super.metadata,
    super.createdAt,
    super.updatedAt,
  });

  factory FFArtist.fromJson(Map<String, dynamic> json) => FFArtist(
        id: json['ID'],
        alias: json['alias'],
        slug: json['slug'],
        email: json['email'] as String?,
        location: json['location'] as String?,
        website: json['website'] as String?,
        fullName: json['fullName'] as String?,
        isArtist: json['isArtist'] as bool?,
        isCurator: json['isCurator'] as bool?,
        avatarURI: json['avatarURI'] as String?,
        bio: json['bio'] as String?,
        accountNumber: json['accountNumber'] as String?,
        type: json['type'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
        linkedAccounts: (json['linkedAccounts'] as List?)
                ?.map((e) => FFUserDetails.fromJson(e))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'ID': id,
        'alias': alias,
        'slug': slug,
        'email': email,
        'location': location,
        'website': website,
        'fullName': fullName,
        'isArtist': isArtist,
        'isCurator': isCurator,
        'avatarURI': avatarURI,
        'bio': bio,
        'accountNumber': accountNumber,
        'type': type,
        'metadata': metadata,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

class FFCurator extends FFUserDetails {
  FFCurator({
    required super.id,
    required super.alias,
    required super.metadata,
    required super.linkedAccounts,
    super.slug,
    super.avatarURI,
    super.bio,
    super.fullName,
    super.isArtist,
    super.isCurator,
    super.type,
    super.createdAt,
    super.updatedAt,
    super.verified,
    super.accountNumber,
    super.location,
    super.website,
    // this.vaultAddresses,
    super.childs,
  });

  // fromJSon
  factory FFCurator.fromJson(Map<String, dynamic> json) => FFCurator(
        id: json['ID'],
        alias: json['alias'],
        slug: json['slug'],
        avatarURI: json['avatarURI'],
        bio: json['bio'],
        fullName: json['fullName'],
        isArtist: json['isArtist'] as bool?,
        isCurator: json['isCurator'] as bool?,
        type: json['type'],
        metadata: json['metadata'],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'])
            : null,
        linkedAccounts: (json['linkedAccounts'] as List?)
                ?.map((e) => FFUserDetails.fromJson(e))
                .toList() ??
            [],
        verified: json['verified'] as bool?,
        accountNumber: json['accountNumber'] as String?,
        location: json['location'] as String?,
        website: json['website'] as String?,
        // vaultAddresses: json['vaultAddresses'] != null
        //     ? VaultAddress.fromJson(json['vaultAddresses'])
        //     : null,
        childs: (json['childs'] as List?)
            ?.map((e) => FFUserDetails.fromJson(e))
            .toList(),
      );

  // toJson
  Map<String, dynamic> toJson() => {
        'ID': id,
        'alias': alias,
        'slug': slug,
        'avatarURI': avatarURI,
        'bio': bio,
        'fullName': fullName,
        'isArtist': isArtist,
        'isCurator': isCurator,
        'type': type,
        'metadata': metadata,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'linkedAccounts': linkedAccounts.map((e) => e.toJson()).toList(),
        'verified': verified,
        'accountNumber': accountNumber,
        'location': location,
        'website': website,
        // 'vaultAddresses': vaultAddresses?.toJson(),
        'childs': childs?.map((e) => e.toJson()).toList(),
      };
}
