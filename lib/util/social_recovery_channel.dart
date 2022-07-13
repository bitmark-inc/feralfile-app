//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/service/social_recovery/shard_deck.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SocialRecoveryChannel {
  static const MethodChannel _channel = const MethodChannel('social_recovery');

  Future<List<ContactDeck>> getContactDecks() async {
    Map res = await _channel.invokeMethod('getContactDecks', {});
    if (res['error'] == 0) {
      List<ContactDeck> contactDecks = [];
      for (final contactDeckJson in res["contactDecks"]) {
        try {
          final contactDeck = ContactDeck.fromJson(jsonDecode(contactDeckJson));
          contactDecks.add(contactDeck);
        } catch (exception) {
          Sentry.captureException(exception);
        }
      }

      return contactDecks;
    } else {
      throw SystemException(res['reason']);
    }
  }

  Future storeContactDeck(ContactDeck contactDeck) async {
    Map res = await _channel.invokeMethod('storeContactDeck', {
      "uuid": contactDeck.uuid,
      "contactDeck": jsonEncode(contactDeck),
    });

    if (res['error'] == 0) {
      return;
    } else {
      throw SystemException(res['reason']);
    }
  }

  Future deleteHelpingContactDecks() async {
    Map res = await _channel.invokeMethod('deleteHelpingContactDecks');

    if (res['error'] == 0) {
      return;
    } else {
      throw SystemException(res['reason']);
    }
  }
}
