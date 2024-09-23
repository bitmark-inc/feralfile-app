import 'package:autonomy_flutter/model/ff_user.dart';
import 'package:autonomy_flutter/util/alias_helper.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';

extension FFUserExt on FFUser {
  String get displayAlias =>
      AliasHelper.transform(alias, isArtistOrCurator: true);

  String? get avatarUrl => (avatarURI != null && avatarURI!.isNotEmpty)
      ? getFFUrl(avatarURI!)
      : null;

  String? get instagramUrl {
    final instagramID = metadata?['instagramID'];
    if (instagramID == null || instagramID.isEmpty) {
      return null;
    }

    if (instagramID!.startsWith('http') || instagramID.startsWith('www')) {
      return instagramID;
    }

    if (instagramID.startsWith('@')) {
      return 'https://www.instagram.com/${instagramID.substring(1)}';
    }

    return 'https://www.instagram.com/$instagramID';
  }

  String? get twitterUrl {
    final twitterID = metadata?['twitterID'];
    if (twitterID == null || twitterID.isEmpty) {
      return null;
    }

    if (twitterID!.startsWith('http') || twitterID.startsWith('www')) {
      return twitterID;
    }

    if (twitterID.startsWith('@')) {
      return 'https://twitter.com/${twitterID.substring(1)}';
    }

    return 'https://twitter.com/$twitterID';
  }

  FFArtist toFFArtist() => FFArtist(
        id: id,
        alias: alias,
        slug: slug,
        avatarURI: avatarURI,
        bio: bio,
        fullName: fullName,
        isArtist: isArtist,
        isCurator: isCurator,
        type: type,
        // email: null,
        metadata: metadata,
        linkedAccounts: linkedAccounts,
        createdAt: createdAt,
        updatedAt: updatedAt,
        verified: verified,
        accountNumber: accountNumber,
      );
}

extension FFUserDetailsExt on FFUserDetails {
  FFArtist toFFArtist() => FFArtist(
        id: id,
        alias: alias,
        slug: slug,
        avatarURI: avatarURI,
        bio: bio,
        fullName: fullName,
        isArtist: isArtist,
        isCurator: isCurator,
        type: type,
        // email: null,
        metadata: metadata,
        linkedAccounts: linkedAccounts,
        createdAt: createdAt,
        updatedAt: updatedAt,
        verified: verified,
        accountNumber: accountNumber,
      );

  FFCurator toFFCurator() => FFCurator(
        id: id,
        alias: alias,
        slug: slug,
        avatarURI: avatarURI,
        bio: bio,
        fullName: fullName,
        isArtist: isArtist,
        isCurator: isCurator,
        type: type,
        metadata: metadata,
        linkedAccounts: linkedAccounts,
        createdAt: createdAt,
        updatedAt: updatedAt,
        verified: verified,
        accountNumber: accountNumber,
      );
}
