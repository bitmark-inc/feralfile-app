import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/additional_data/additional_data.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/service/client_token_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';
import 'package:nft_collection/database/nft_collection_database.dart';

class ViewPostcard extends AdditionalData {
  final String indexID;

  ViewPostcard({
    required this.indexID,
    required super.notificationType,
    super.announcementContentId,
    super.linkText,
  });

  @override
  bool get isTappable => true;

  @override
  Future<void> handleTap(BuildContext context) async {
    log.info('ViewPostcard: handle tap');

    final tokens = await injector<NftCollectionDatabase>()
        .assetTokenDao
        .findAllAssetTokensByTokenIDs([indexID]);
    if (tokens.isEmpty) {
      return;
    }
    final owner = tokens.first.owner;
    final postcardDetailPayload = PostcardDetailPagePayload(
      ArtworkIdentity(indexID, owner),
      useIndexer: true,
    );
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).popUntil((route) =>
        route.settings.name == AppRouter.homePage ||
        route.settings.name == AppRouter.homePageNoTransition);
    unawaited(Navigator.of(context).pushNamed(
        AppRouter.claimedPostcardDetailsPage,
        arguments: postcardDetailPayload));
  }

  @override
  bool prepareAndDidSuccess() {
    unawaited(injector<ClientTokenService>().refreshTokens());
    return true;
  }
}
