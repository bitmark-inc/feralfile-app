import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/additional_data/additional_data.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/gift_handler.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';

class GiftMembership extends AdditionalData {
  final String? giftCode;

  GiftMembership({
    required this.giftCode,
    required super.notificationType,
    super.announcementContentId,
  });

  @override
  bool get isTappable => true;

  @override
  Future<void> handleTap(
      BuildContext context, PageController? pageController) async {
    log.info('GiftMembership: handle tap: $giftCode');
    await GiftHandler.handleGiftMembership(giftCode);
  }

  @override
  Future<bool> prepareBeforeShowing() async {
    final isSubscribe = await injector<IAPService>().isSubscribed();
    return !isSubscribe;
  }
}
