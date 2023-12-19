import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:nft_collection/models/asset_token.dart';

extension ChatMessageExtension on SystemMessage {
  bool get isCompletedPostcardMessage => text == 'postcard_complete';

  bool get isSystemMessage => author.isSystemUser;
}

extension UserExtension on User {
  bool get isSystemUser => id == 'system';

  String getName(
      {required AssetToken assetToken, required Map<String, String> aliases}) {
    if (isSystemUser) {
      return 'system'.tr();
    }
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    final artists = assetToken.getArtists
      ..removeWhere((element) => element.id == null);
    final artist = artists.firstWhereOrNull((element) => element.id == id);
    if (artists.isEmpty || artist == null) {
      return 'pending_stamper'.tr();
    } else {
      final alias = aliases[artist.id];
      if (alias != null && alias.isNotEmpty) {
        return alias;
      }
      final index = artists.indexOf(artist) + 1;
      return 'stamper_'.tr(args: [index.toString()]);
    }
  }

  String getAvatarUrl({required AssetToken assetToken}) {
    if (isSystemUser) {
      return 'assets/images/moma_bot_logo.svg';
    }
    if (imageUrl != null) {
      return imageUrl!;
    }
    final artists = assetToken.getArtists;
    final artist = artists.firstWhereOrNull((element) => element.id == id);
    if (artists.isEmpty || artist == null) {
      return '';
    }
    int index = artists.indexOf(artist);
    final numberFormater = NumberFormat('00');
    return '${assetToken.getPreviewUrl()}/assets/stamps/${numberFormater.format(index)}.png';
  }
}
