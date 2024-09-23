import 'package:autonomy_flutter/model/ff_user.dart';
import 'package:autonomy_flutter/util/alias_helper.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';

extension FFUserExt on FFUser {
  String get displayAlias => AliasHelper.transform(alumniAccount?.alias ?? id,
      isArtistOrCurator: true);

  String? get avatarUrl =>
      (alumniAccount?.avatarURI != null && alumniAccount!.avatarURI!.isNotEmpty)
          ? getFFUrl(alumniAccount!.avatarURI!)
          : null;

  String? get instagramUrl {
    final instagramID = alumniAccount?.socialNetworks?.instagramID;
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
    final twitterID = alumniAccount?.socialNetworks?.twitterID;
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
}
