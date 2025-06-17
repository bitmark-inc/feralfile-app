class AlumniAccount {
  AlumniAccount({
    required this.id,
    this.alias,
    this.slug,
    this.fullName,
    this.isArtist,
    this.isCurator,
    this.bio,
    this.email,
    this.avatarURI,
    this.avatarDisplay,
    this.location,
    this.website,
    this.company,
    this.socialNetworks,
    this.addresses,
    this.associatedAddresses,
    this.collaborationAlumniAccounts,
  });

  factory AlumniAccount.fromJson(Map<String, dynamic> json) => AlumniAccount(
        id: json['ID'] as String,
        alias: json['alias'] as String?,
        slug: json['slug'] as String?,
        fullName: json['fullName'] as String?,
        isArtist: json['isArtist'] as bool?,
        isCurator: json['isCurator'] as bool?,
        bio: json['bio'] as String?,
        email: json['email'] as String?,
        avatarURI: json['avatarURI'] as String?,
        avatarDisplay: json['avatarDisplay'] as String?,
        location: json['location'] as String?,
        website: json['website'] as String?,
        company: json['company'] as String?,
        socialNetworks: json['socialNetworks'] != null
            ? SocialNetwork.fromJson(
                Map<String, dynamic>.from(json['socialNetworks'] as Map),
              )
            : null,
        addresses: json['addresses'] != null
            ? AlumniAccountAddresses.fromJson(
                Map<String, dynamic>.from(json['addresses'] as Map),
              )
            : null,
        associatedAddresses: (json['associatedAddresses'] as List?)
            ?.map((e) => e as String)
            .toList(),
        collaborationAlumniAccounts:
            (json['collaborationAlumniAccounts'] as List?)
                ?.map((e) => AlumniAccount.fromJson(e as Map<String, dynamic>))
                .toList(),
      );
  final String id;
  final String? alias;
  final String? slug;
  final String? fullName;
  final bool? isArtist;
  final bool? isCurator;
  final String? bio;
  final String? email;
  final String? avatarURI;
  final String? avatarDisplay;
  final String? location;
  final String? website;
  final String? company;
  final SocialNetwork? socialNetworks;
  final AlumniAccountAddresses? addresses;
  final List<String>? associatedAddresses;
  final List<AlumniAccount>? collaborationAlumniAccounts;

  Map<String, dynamic> toJson() => {
        'ID': id,
        'alias': alias,
        'slug': slug,
        'fullName': fullName,
        'isArtist': isArtist,
        'isCurator': isCurator,
        'bio': bio,
        'email': email,
        'avatarURI': avatarURI,
        'avatarDisplay': avatarDisplay,
        'location': location,
        'website': website,
        'company': company,
        'socialNetworks': socialNetworks?.toJson(),
        'addresses': addresses?.toJson(),
        'associatedAddresses': associatedAddresses,
        'collaborationAlumniAccounts':
            collaborationAlumniAccounts?.map((e) => e.toJson()).toList(),
      };

  // copyWith
  AlumniAccount copyWith({
    String? id,
    String? alias,
    String? slug,
    String? fullName,
    bool? isArtist,
    bool? isCurator,
    String? bio,
    String? email,
    String? avatarURI,
    String? avatarDisplay,
    String? location,
    String? website,
    String? company,
    SocialNetwork? socialNetworks,
    AlumniAccountAddresses? addresses,
    List<String>? associatedAddresses,
    List<AlumniAccount>? collaborationAlumniAccounts,
  }) {
    return AlumniAccount(
      id: id ?? this.id,
      alias: alias ?? this.alias,
      slug: slug ?? this.slug,
      fullName: fullName ?? this.fullName,
      isArtist: isArtist ?? this.isArtist,
      isCurator: isCurator ?? this.isCurator,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      avatarURI: avatarURI ?? this.avatarURI,
      avatarDisplay: avatarDisplay ?? this.avatarDisplay,
      location: location ?? this.location,
      website: website ?? this.website,
      company: company ?? this.company,
      socialNetworks: socialNetworks ?? this.socialNetworks,
      addresses: addresses ?? this.addresses,
      associatedAddresses:
          associatedAddresses ?? this.associatedAddresses?.toList(),
      collaborationAlumniAccounts: collaborationAlumniAccounts ??
          this.collaborationAlumniAccounts?.toList(),
    );
  }
}

class SocialNetwork {
  SocialNetwork({
    this.instagramID,
    this.twitterID,
  });

  factory SocialNetwork.fromJson(Map<String, dynamic> json) => SocialNetwork(
        instagramID: json['instagramID'] as String?,
        twitterID: json['twitterID'] as String?,
      );
  final String? instagramID;
  final String? twitterID;

  Map<String, dynamic> toJson() => {
        'instagramID': instagramID,
        'twitterID': twitterID,
      };
}

class AlumniAccountAddresses {
  AlumniAccountAddresses({
    this.ethereum,
    this.tezos,
    this.bitmark,
  });

  factory AlumniAccountAddresses.fromJson(Map<String, dynamic> json) =>
      AlumniAccountAddresses(
        ethereum: json['ethereum'] as String?,
        tezos: json['tezos'] as String?,
        bitmark: json['bitmark'] as String?,
      );
  final String? ethereum;
  final String? tezos;
  final String? bitmark;

  Map<String, dynamic> toJson() => {
        'ethereum': ethereum,
        'tezos': tezos,
        'bitmark': bitmark,
      };
}
