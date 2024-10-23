import 'package:autonomy_flutter/model/ff_alumni.dart';
import 'package:autonomy_flutter/util/alias_helper.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';

extension AlumniAccountExt on AlumniAccount {
  String get displayAlias =>
      AliasHelper.transform(alias ?? id, isArtistOrCurator: true);

  String? get avatarUrl => (avatarURI != null && avatarURI!.isNotEmpty)
      ? getFFUrl(avatarURI!)
      : null;

  String? get instagramUrl {
    final instagramID = socialNetworks?.instagramID;
    if (instagramID == null || instagramID.isEmpty) {
      return null;
    }

    if (instagramID.startsWith('http') || instagramID.startsWith('www')) {
      return instagramID;
    }

    if (instagramID.startsWith('@')) {
      return 'https://www.instagram.com/${instagramID.substring(1)}';
    }

    return 'https://www.instagram.com/$instagramID';
  }

  String? get twitterUrl {
    final twitterID = socialNetworks?.twitterID;
    if (twitterID == null || twitterID.isEmpty) {
      return null;
    }

    if (twitterID.startsWith('http') || twitterID.startsWith('www')) {
      return twitterID;
    }

    if (twitterID.startsWith('@')) {
      return 'https://twitter.com/${twitterID.substring(1)}';
    }

    return 'https://twitter.com/$twitterID';
  }

  List<String?> get addressesList {
    final addresses = this.addresses;
    if (addresses == null) {
      return [];
    }

    return [
      addresses.bitmark,
      addresses.ethereum,
      addresses.tezos,
    ];
  }

  List<String> get allRelatedAccountIDs {
    final List<String> accountIDs = [id];
    if (collaborationAlumniAccounts != null) {
      accountIDs.addAll(collaborationAlumniAccounts!.map((e) => e.id));
    }

    return accountIDs;
  }
}
