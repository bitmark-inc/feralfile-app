//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/wc2_pairing.dart';
import 'package:autonomy_flutter/model/wc2_proposal.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_sign_message_page.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wc2_channel.dart';
import 'package:collection/collection.dart';

class Wc2Service extends Wc2Handler {
  static final Set<String> _supportedChains = {
    "autonomy",
    "eip155",
    "tezos",
  };

  static final Set<String> _supportedMethods = {
    "au_sign",
    "au_permissions",
    "au_sendTransaction"
  };

  final NavigationService _navigationService;

  late Wc2Channel _wc2channel;

  Wc2Service(this._navigationService) {
    _wc2channel = Wc2Channel(handler: this);
  }

  Future connect(String uri) async {
    await _wc2channel.pairClient(uri);
  }

  Future approveSession(
    String id, {
    required String accountDid,
  }) async {
    await _wc2channel.approve(
      id,
      accountDid,
    );
  }

  Future rejectSession(
    String id, {
    String? reason,
  }) async {
    await _wc2channel.reject(
      id,
      reason: reason,
    );
  }

  Future respondOnApprove(String topic, String response) async {
    await _wc2channel.respondOnApprove(topic, response);
  }

  Future respondOnReject(
    String topic, {
    String? reason,
  }) async {
    await _wc2channel.respondOnReject(
      topic: topic,
      reason: reason,
    );
  }

  Future<List<Wc2Pairing>> getPairings() async {
    return await _wc2channel.getPairings();
  }

  Future deletePairing({required String topic}) async {
    log.info("[Wc2Service] Delete pairing. Topic: $topic");
    return await _wc2channel.deletePairing(topic: topic);
  }

  @override
  void onSessionProposal(Wc2Proposal proposal) async {
    final unsupportedChains =
        proposal.requiredNamespaces.keys.toSet().difference(_supportedChains);
    if (unsupportedChains.isNotEmpty) {
      log.info("[Wc2Service] Proposal contains unsupported chains: "
          "$unsupportedChains");
      await rejectSession(
        proposal.id,
        reason: "Chains ${unsupportedChains.join(", ")} not supported",
      );
      return;
    }

    final proposalMethods = proposal.requiredNamespaces.values
        .map((e) => e.methods)
        .flattened
        .toSet();
    final unsupportedMethods = proposalMethods.difference(_supportedMethods);
    if (unsupportedMethods.isNotEmpty) {
      log.info("[Wc2Service] Proposal contains unsupported methods: "
          "$unsupportedMethods");
      await rejectSession(
        proposal.id,
        reason: "Methods ${unsupportedMethods.join(", ")} not supported",
      );
      return;
    }
    _navigationService.navigateTo(AppRouter.wc2ConnectPage,
        arguments: proposal);
  }

  @override
  void onSessionRequest(Wc2Request request) async {
    if (request.method == "au_sign") {
      _navigationService.navigateTo(WCSignMessagePage.tag,
          arguments: WCSignMessagePageArgs(
            request.id,
            request.topic,
            request.proposer!.toWCPeerMeta(),
            request.params["message"],
            "", // uuid, used for Wallet connect 1 only
            wc2Params: Wc2SignRequestParams(
              chain: request.params["chain"],
              address: request.params["address"],
              message: request.params["message"],
            ),
          ));
    } else if (request.method == "au_permissions") {
      _navigationService.navigateTo(
        AppRouter.wc2PermissionPage,
        arguments: request,
      );
    } else if (request.method == "au_sendTransaction") {
      // TODO: handle send transaction request
      // https://github.com/bitmark-inc/autonomy/issues/1630
    } else {
      log.info("[Wc2Service] Unsupported method: ${request.method}");
      await respondOnReject(
        request.topic,
        reason: "Method ${request.method} is not supported",
      );
    }
  }
}
