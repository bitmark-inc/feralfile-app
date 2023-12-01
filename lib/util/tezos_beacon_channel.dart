//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/p2p_peer.dart';
import 'package:autonomy_flutter/model/tezos_connection.dart';
import 'package:flutter/services.dart';
import 'package:tezart/tezart.dart';

class TezosBeaconChannel {
  static const MethodChannel _channel = MethodChannel('tezos_beacon');
  static const EventChannel _eventChannel = EventChannel('tezos_beacon/event');

  TezosBeaconChannel({required this.handler}) {
    unawaited(listen());
  }

  BeaconHandler? handler;

  Future connect() async {
    await Future.delayed(const Duration(seconds: 2));
    await _channel.invokeMethod('connect', {});
  }

  Future<P2PPeer> addPeer(String link) async {
    final Map res = await _channel.invokeMethod('addPeer', {'link': link});
    final peerData = json.decode(res['result']);
    return P2PPeer.fromJson(peerData);
  }

  Future removePeer(P2PPeer peer) async {
    final peerJSON = json.encode(peer);
    await _channel.invokeMethod('removePeer', {'peer': peerJSON});
  }

  Future cleanup(List<String> ids) async {
    await _channel.invokeMethod('cleanup', {'retain_ids': ids});
  }

  Future permissionResponse(
      String id, String? publicKey, String? address) async {
    await _channel.invokeMethod(
        'response', {'id': id, 'publicKey': publicKey, 'address': address});
  }

  Future signResponse(String id, String? signature) async {
    await _channel.invokeMethod('response', {'id': id, 'signature': signature});
  }

  Future operationResponse(String id, String? txHash) async {
    await _channel.invokeMethod('response', {'id': id, 'txHash': txHash});
  }

  Future<void> listen() async {
    await for (Map event in _eventChannel.receiveBroadcastStream()) {
      var params = event['params'];
      switch (event['eventName']) {
        case 'observeRequest':
          final String id = params['id'];
          final String senderID = params['senderID'];
          final String version = params['version'];
          final String originID = params['originID'];
          final String type = params['type'];
          final String? appName = params['appName'];
          final String? icon = params['icon'];

          final request = BeaconRequest(
            id,
            senderID: senderID,
            version: version,
            originID: originID,
            type: type,
            appName: appName,
            icon: icon,
          );
          switch (type) {
            case 'signPayload':
              final String? payload = params['payload'];
              final String? sourceAddress = params['sourceAddress'];
              request.payload = payload;
              request.sourceAddress = sourceAddress;
              break;
            case 'operation':
              final List operationsDetails = params['operationDetails'];
              final String? sourceAddress = params['sourceAddress'];

              List<Operation> operations = [];
              for (var element in operationsDetails) {
                final String? kind = element['kind'];
                final String? storageLimit = element['storageLimit'];
                final String? gasLimit = element['gasLimit'];
                final String? fee = element['fee'];

                if (kind == 'origination') {
                  final String balance = element['balance'] ?? '0';
                  final List<dynamic> code = element['code'];
                  final dynamic storage = element['storage'];

                  final operation = OriginationOperation(
                    balance: int.parse(balance),
                    code:
                        code.map((e) => Map<String, dynamic>.from(e)).toList(),
                    storage: storage,
                    customFee: fee != null ? int.parse(fee) : null,
                    customGasLimit:
                        gasLimit != null ? int.parse(gasLimit) : null,
                    customStorageLimit:
                        storageLimit != null ? int.parse(storageLimit) : null,
                  );
                  operations.add(operation);
                } else {
                  final String destination = element['destination'] ?? '';
                  final String amount = element['amount'] ?? '0';
                  final String? entrypoint = element['entrypoint'];
                  final dynamic parameters = element['parameters'] != null
                      ? json.decode(json.encode(element['parameters']))
                      : null;

                  final operation = TransactionOperation(
                      amount: int.parse(amount),
                      destination: destination,
                      entrypoint: entrypoint,
                      params: parameters,
                      customFee: fee != null ? int.parse(fee) : null,
                      customGasLimit:
                          gasLimit != null ? int.parse(gasLimit) : null,
                      customStorageLimit: storageLimit != null
                          ? int.parse(storageLimit)
                          : null);

                  operations.add(operation);
                }
              }

              request.operations = operations;
              request.sourceAddress = sourceAddress;
              break;
          }

          handler!.onRequest(request);
          break;
        case 'observeEvent':
          switch (params['type']) {
            case 'beaconRequestedPermission':
              final Uint8List data = params['peer'];
              Peer peer = Peer.fromJson(json.decode(utf8.decode(data)));
              handler!.onRequestedPermission(peer);
              break;
            case 'error':
              break;
            case 'userAborted':
              handler!.onAbort();
              break;
          }
      }
    }
  }
}

abstract class BeaconHandler {
  void onRequest(BeaconRequest request);

  void onRequestedPermission(Peer peer);

  void onAbort();
}
