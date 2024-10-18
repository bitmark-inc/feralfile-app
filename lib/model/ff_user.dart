class FFUser {
  final String id;
  final bool? isArtist;
  final bool? isCurator;
  final String? accountNumber;
  final AlumniAccount? alumniAccount;

  FFUser({
    required this.id,
    this.isArtist,
    this.isCurator,
    this.accountNumber,
    this.alumniAccount,
  });

  // fromJSon
  factory FFUser.fromJson(Map<String, dynamic> json) => FFUser(
        id: json['ID'],
        isArtist: json['isArtist'] as bool?,
        isCurator: json['isCurator'] as bool?,
        accountNumber: json['accountNumber'] as String?,
        alumniAccount: json['alumniAccount'] != null
            ? AlumniAccount.fromJson(json['alumniAccount'])
            : null,
      );

  // toJson
  Map<String, dynamic> toJson() => {
        'ID': id,
        'isArtist': isArtist,
        'isCurator': isCurator,
        'accountNumber': accountNumber,
      };
}

class AlumniAccount {
  final String? alias;
  final String? slug;
  final String? avatarURI;
  final String? fullName;
  final String? bio;
  final String? location;
  final String? website;
  final List<String>? linkedAddresses;
  final SocialNetwork? socialNetworks;

  AlumniAccount({
    this.alias,
    this.slug,
    this.avatarURI,
    this.fullName,
    this.bio,
    this.location,
    this.website,
    this.linkedAddresses,
    this.socialNetworks,
  });

  factory AlumniAccount.fromJson(Map<String, dynamic> json) => AlumniAccount(
      alias: json['alias'] as String?,
      slug: json['slug'] as String?,
      avatarURI: json['avatarURI'] as String?,
      fullName: json['fullName'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      website: json['website'] as String?,
      linkedAddresses:
          (json['linkedAddresses'] as List?)?.map((e) => e as String).toList(),
      socialNetworks: json['socialNetworks'] != null
          ? SocialNetwork.fromJson(json['socialNetworks'])
          : null);

  Map<String, dynamic> toJson() => {
        'alias': alias,
        'slug': slug,
        'avatarURI': avatarURI,
        'fullName': fullName,
        'bio': bio,
        'location': location,
        'website': website,
        'linkedAddresses': linkedAddresses,
        'socialNetworks': socialNetworks?.toJson(),
      };
}

class SocialNetwork {
  final String? instagramID;
  final String? twitterID;

  SocialNetwork({
    this.instagramID,
    this.twitterID,
  });

  factory SocialNetwork.fromJson(Map<String, dynamic> json) => SocialNetwork(
        instagramID: json['instagramID'] as String?,
        twitterID: json['twitterID'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'instagramID': instagramID,
        'twitterID': twitterID,
      };
}
