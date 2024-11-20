import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/additional_data/additional_data.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/service/chat_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/shared.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/database/nft_collection_database.dart';

class ViewNewMessage extends AdditionalData {
  final String groupId;

  ViewNewMessage({
    required this.groupId,
    required super.notificationType,
    super.announcementContentId,
    super.cta,
  });

  final RemoteConfigService _remoteConfigService =
      injector<RemoteConfigService>();

  @override
  bool get isTappable => true;

  @override
  Future<void> handleTap(BuildContext context) async {
    log.info('ViewNewMessage: handle tap: $groupId');
    if (!_remoteConfigService.getBool(ConfigGroup.viewDetail, ConfigKey.chat)) {
      return;
    }

    final tokens = await injector<NftCollectionDatabase>()
        .assetTokenDao
        .findAllAssetTokensByTokenIDs([groupId]);
    final owner = tokens.first.owner;
    final isSkip =
        injector<ChatService>().isConnecting(address: owner, id: groupId);
    if (isSkip) {
      return;
    }
    final GlobalKey<ClaimedPostcardDetailPageState> key = GlobalKey();
    final postcardDetailPayload =
        PostcardDetailPagePayload(ArtworkIdentity(groupId, owner), key: key);
    if (!context.mounted) {
      return;
    }
    unawaited(Navigator.of(context).pushNamed(
        AppRouter.claimedPostcardDetailsPage,
        arguments: postcardDetailPayload));
    Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      final state = key.currentState;
      final assetToken =
          key.currentContext?.read<PostcardDetailBloc>().state.assetToken;
      if (state != null && assetToken != null) {
        unawaited(state.gotoChatThread(key.currentContext!));
        timer.cancel();
      }
    });
  }

  @override
  bool prepareAndDidSuccess() {
    if (!_remoteConfigService.getBool(ConfigGroup.viewDetail, ConfigKey.chat)) {
      return false;
    }
    final currentGroupId = memoryValues.currentGroupChatId;
    if (groupId == currentGroupId) {
      return false;
    }
    return true;
  }
}
