//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/wc2_pairing.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/services.dart';

class Wc2Channel {
  static const MethodChannel _channel = MethodChannel('wallet_connect_v2');
  static const EventChannel _eventChannel =
      EventChannel('wallet_connect_v2/event');

  Wc2Channel({required this.handler}) {
    unawaited(listen());
  }

  Wc2Handler? handler;

  Future pairClient(String uri) async {
    await _channel.invokeMethod('pairClient', {'uri': uri});
  }

  Future approve(String proposalId, String accountDid) async {
    await _channel.invokeMethod('approve', {
      'proposal_id': proposalId,
      'account': accountDid,
    });
  }

  Future reject(
    String proposalId, {
    String? reason,
  }) async {
    await _channel.invokeMethod('reject', {
      'proposal_id': proposalId,
      if (reason?.isNotEmpty == true) ...{
        'reason': reason,
      }
    });
  }

  Future respondOnApprove(String topic, String response) async {
    await _channel.invokeMethod('respondOnApprove', {
      'topic': topic,
      'response': response,
    });
  }

  Future respondOnReject({
    required String topic,
    String? reason,
  }) async {
    await _channel.invokeMethod('respondOnReject', {
      'topic': topic,
      if (reason?.isNotEmpty == true) ...{
        'reason': reason,
      }
    });
  }

  Future<List<Wc2Pairing>> getPairings() async {
    final jsonString = await _channel.invokeMethod('getPairings');
    final json = jsonDecode(jsonString) as List<dynamic>;
    return json.map((e) => Wc2Pairing.fromJson(e)).toList();
  }

  Future deletePairing({required String topic}) async {
    await _channel.invokeMethod('deletePairing', {
      'topic': topic,
    });
  }

  Future cleanup(List<String> ids) async {
    await _channel.invokeMethod('cleanup', {'retain_ids': ids});
  }

  Future<void> listen() async {
    await for (Map event in _eventChannel.receiveBroadcastStream()) {
      var params = event['params'];
      switch (event['eventName']) {
        case 'onConnected':
          log.info('[WC2Channel] onConnected');
          break;
        case 'onSessionProposal':
          log.info('[WC2Channel] onSessionProposal');
          final id = params['id'];
          final proposer =
              AppMetadata.fromJson(json.decode(params['proposer']));
          final Map<String, dynamic> requiredNamespacesJson =
              json.decode(params['requiredNamespaces']);
          final Map<String, Wc2Namespace> requiredNamespaces =
              requiredNamespacesJson.map(
                  (key, value) => MapEntry(key, Wc2Namespace.fromJson(value)));
          final Map<String, dynamic> optionalNamespacesJson =
              json.decode(params['optionalNamespaces']);
          final Map<String, Wc2Namespace> optionalNamespaces =
              optionalNamespacesJson.map(
                  (key, value) => MapEntry(key, Wc2Namespace.fromJson(value)));
          final request = Wc2Proposal(
            id,
            proposer: proposer,
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
          );
          handler?.onSessionProposal(request);
          break;
        case 'onSessionSettle':
          log.info('[WC2Channel] onSessionSettle');
          break;
        case 'onSessionRequest':
          log.info('[WC2Channel] onSessionRequest');
          log.info(params);
          final request = Wc2Request.fromJson(json.decode(params));
          handler?.onSessionRequest(request);
          break;
        case 'onSessionDelete':
          log.info('[WC2Channel] onSessionDelete');
          break;
      }
    }
  }
}

abstract class Wc2Handler {
  void onSessionRequest(Wc2Request request);

  void onSessionProposal(Wc2Proposal proposal);
}
