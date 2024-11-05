import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/additional_data/additional_data.dart';
import 'package:autonomy_flutter/service/client_token_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/john_gerrard_helper.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';

class JgCrystallineWorkGenerated extends AdditionalData {
  final String tokenId;

  JgCrystallineWorkGenerated({
    required this.tokenId,
    required super.notificationType,
    super.announcementContentId,
    super.linkText,
  });

  @override
  bool get isTappable => true;

  @override
  Future<void> handleTap(BuildContext context) async {
    log.info('JgCrystallineWorkGenerated: handle tap');

    final indexId = JohnGerrardHelper.getIndexID(tokenId);
    await injector<NavigationService>().gotoArtworkDetailsPage(indexId);
  }

  @override
  Future<bool> prepareAndDidSuccess() async {
    unawaited(injector<ClientTokenService>().refreshTokens());
    return true;
  }
}
