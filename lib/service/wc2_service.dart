//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/wc2_pairing.dart';
import 'package:autonomy_flutter/model/wc2_proposal.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/au_sign_message_page.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_sign_message_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_sign_message_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wc2_channel.dart';
import 'package:autonomy_flutter/util/wc2_ext.dart';
import 'package:autonomy_flutter/util/wc2_tezos_ext.dart';
import 'package:collection/collection.dart';
import 'package:wallet_connect/wallet_connect.dart';

import '../database/cloud_database.dart';
import '../database/entity/connection.dart';

class Wc2Service extends Wc2Handler {
  static final Set<String> _supportedChains = {
    Wc2Chain.autonomy,
    Wc2Chain.ethereum,
    Wc2Chain.tezos,
  };

  static final Set<String> _supportedMethods = {
    "au_sign",
    "au_permissions",
    "au_sendTransaction"
  };

  final NavigationService _navigationService;
  final AccountService _accountService;
  final CloudDatabase _cloudDB;

  late Wc2Channel _wc2channel;
  String pendingUri = "";

  Wc2Service(
    this._navigationService,
    this._accountService,
    this._cloudDB,
  ) {
    _wc2channel = Wc2Channel(handler: this);
  }

  Future connect(String uri) async {
    pendingUri = uri;
    await _wc2channel.pairClient(uri);
  }

  Future activateParings() async {
    final connections = await _cloudDB.connectionDao
        .getConnectionsByType(ConnectionType.walletConnect2.rawValue);
    for (var connection in connections) {
      final topic = connection.key.split(":").lastOrNull;
      if (topic == null) continue;
      await _wc2channel.activate(topic: topic);
    }
  }

  Future cleanup() async {
    final connections = await _cloudDB.connectionDao
        .getConnectionsByType(ConnectionType.walletConnect2.rawValue);
    final ids = connections
        .map((e) => e.key.split(":").lastOrNull)
        .whereNotNull()
        .toList();

    _wc2channel.cleanup(ids);
  }

  Future approveSession(Wc2Proposal proposal,
      {required String accountDid, required String personalUUID}) async {
    await _wc2channel.approve(
      proposal.id,
      accountDid,
    );
    final wc2Pairings = await injector<Wc2Service>().getPairings();
    final topic = wc2Pairings
            .firstWhereOrNull((element) => pendingUri.contains(element.topic))
            ?.topic ??
        "";
    final connection = Connection(
      key: "$personalUUID:$topic",
      name: proposal.proposer.name,
      data: json.encode(proposal.proposer),
      connectionType: ConnectionType.walletConnect2.rawValue,
      accountNumber: accountDid,
      createdAt: DateTime.now(),
    );
    await _cloudDB.connectionDao.insertConnection(connection);
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
    log.info("[Wc2Service] respondOnReject topic $topic, reason: $reason");
    await _wc2channel.respondOnReject(
      topic: topic,
      reason: reason,
    );
  }

  //#region Pairing
  Future<List<Wc2Pairing>> getPairings() async {
    return await _wc2channel.getPairings();
  }

  Future deletePairing({required String topic}) async {
    log.info("[Wc2Service] Delete pairing. Topic: $topic");
    return await _wc2channel.deletePairing(topic: topic);
  }

  //#endregion

  //#region Events handling
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
      switch (request.chainId.caip2Namespace) {
        case Wc2Chain.ethereum:
          await _handleEthereumSignRequest(request);
          break;
        case Wc2Chain.tezos:
          await _handleTezosSignRequest(request);
          break;
        case Wc2Chain.autonomy:
          await _handleAutonomySignRequest(request);
          break;
        default:
          log.info("[Wc2Service] Unsupported chain: ${request.method}");
          await respondOnReject(
            request.topic,
            reason: "Chain ${request.chainId} is not supported",
          );
      }
    } else if (request.method == "au_permissions") {
      _navigationService.navigateTo(
        AppRouter.wc2PermissionPage,
        arguments: request,
      );
    } else if (request.method == "au_sendTransaction") {
      final chain = request.params["chain"] as String;
      switch (chain.caip2Namespace) {
        case Wc2Chain.ethereum:
          try {
            final account = await _accountService.getAccountByAddress(
              chain: chain,
              address: request.params["address"],
            );
            var transaction =
                request.params["transactions"][0] as Map<String, dynamic>;
            if (transaction["data"] == null) transaction["data"] = "";
            if (transaction["gas"] == null) transaction["gas"] = "";
            final metaData = request.proposer != null
                ? request.proposer!.toWCPeerMeta()
                : WCPeerMeta(icons: [], name: "", url: "", description: "");
            final args = WCSendTransactionPageArgs(
              request.id,
              metaData,
              WCEthereumTransaction.fromJson(transaction),
              account.uuid,
              topic: request.topic,
              isWalletConnect2: true,
            );
            _navigationService.navigateTo(
              WCSendTransactionPage.tag,
              arguments: args,
            );
          } catch (e) {
            await respondOnReject(request.topic, reason: "$e");
          }
          break;
        case Wc2Chain.tezos:
          try {
            final beaconReq = request.toBeaconRequest();
            _navigationService.navigateTo(
              TBSendTransactionPage.tag,
              arguments: beaconReq,
            );
          } catch (e) {
            await respondOnReject(request.topic, reason: "$e");
          }
          break;
        default:
          await respondOnReject(
            request.topic,
            reason: "Chain $chain is not supported",
          );
      }
    } else {
      log.info("[Wc2Service] Unsupported method: ${request.method}");
      await respondOnReject(
        request.topic,
        reason: "Method ${request.method} is not supported",
      );
    }
  }

  //#endregion

  //#region Handle sign request
  Future _handleEthereumSignRequest(Wc2Request request) async {
    await _navigationService.navigateTo(WCSignMessagePage.tag,
        arguments: WCSignMessagePageArgs(
          request.id,
          request.topic,
          request.proposer!.toWCPeerMeta(),
          request.params["message"],
          WCSignType.PERSONAL_MESSAGE,
          "", // uuid, used for Wallet connect 1 only
          wc2Params: Wc2SignRequestParams(
            chain: request.params["chain"],
            address: request.params["address"],
            message: request.params["message"],
          ),
        ));
  }

  Future _handleTezosSignRequest(Wc2Request request) async {
    final beaconReq = request.toBeaconRequest();
    await _navigationService.navigateTo(
      TBSignMessagePage.tag,
      arguments: beaconReq,
    );
  }

  Future _handleAutonomySignRequest(Wc2Request request) async {
    await _navigationService.navigateTo(
      AUSignMessagePage.tag,
      arguments: request,
    );
  }
//#endregion
}
