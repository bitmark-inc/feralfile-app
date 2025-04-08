import 'package:autonomy_flutter/model/common.dart';
import 'package:autonomy_flutter/model/ff_alumni.dart';
import 'package:autonomy_flutter/util/alias_helper.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:collection/collection.dart';

extension AlumniAccountExt on AlumniAccount {
  String get displayAlias =>
      AliasHelper.transform(alias ?? id, isArtistOrCurator: true);

  String? get avatarUrl {
    final uri = avatarDisplay?.isNotEmpty ?? false ? avatarDisplay : avatarURI;
    return uri != null
        ? getFFUrl(uri, variant: CloudFlareVariant.m.value)
        : null;
  }

  List<String> get websiteUrl {
    final listRawWebsite =
        website?.split('&').map((e) => e.trim()).where((e) => e.isNotEmpty) ??
            [];
    final listWebsite = listRawWebsite.map((e) {
      if (e.startsWith('http')) {
        return e;
      }

      return 'http://$e';
    }).toList();
    return listWebsite;
  }

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

  List<String> get addressesList {
    final addresses = this.addresses;
    if (addresses == null) {
      return [];
    }
    final list = <String?>[
      addresses.ethereum,
      addresses.tezos,
      // addresses.bitmark,
    ];
    return list.whereNotNull().toList();
  }

  List<String> get allRelatedAccountIDs {
    final List<String> accountIDs = [id];
    if (collaborationAlumniAccounts != null) {
      accountIDs.addAll(collaborationAlumniAccounts!.map((e) => e.id));
    }

    return accountIDs;
  }

  List<String> get allRelatedAddresses {
    final addresses = addressesList.whereNotNull().toList()
      ..addAll(associatedAddresses ?? [])
      ..addAll(collaborationAlumniAccounts
              ?.map((e) => e.addressesList.whereNotNull().toList())
              .flattened ??
          []);
    return addresses;
  }
}
