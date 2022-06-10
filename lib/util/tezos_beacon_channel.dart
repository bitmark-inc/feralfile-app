//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/model/p2p_peer.dart';
import 'package:autonomy_flutter/model/tezos_connection.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:flutter/services.dart';
import 'package:tezart/tezart.dart';

class TezosBeaconChannel {
  static const MethodChannel _channel = const MethodChannel('tezos_beacon');
  static const EventChannel _eventChannel =
      const EventChannel('tezos_beacon/event');

  TezosBeaconChannel({required this.handler}) {
    listen();
  }

  BeaconHandler? handler;

  Future connect() async {
    await _channel.invokeMethod('connect', {});
  }

  Future<P2PPeer> addPeer(String link) async {
    final Map res = await _channel.invokeMethod('addPeer', {"link": link});
    final peerData = json.decode(res['result']);
    return P2PPeer.fromJson(peerData);
  }

  Future removePeer(P2PPeer peer) async {
    final peerJSON = json.encode(peer);
    await _channel.invokeMethod('removePeer', {'peer': peerJSON});
  }

  Future permissionResponse(
      String id, String? publicKey, String? address) async {
    await _channel.invokeMethod(
        'response', {"id": id, "publicKey": publicKey, "address": address});
  }

  Future signResponse(String id, String? signature) async {
    await _channel.invokeMethod('response', {"id": id, "signature": signature});
  }

  Future operationResponse(String id, String? txHash) async {
    await _channel.invokeMethod('response', {"id": id, "txHash": txHash});
  }

  Future<String> getConnectionURI() async {
    Map res = await _channel.invokeMethod('getConnectionURI', {});

    if (res['error'] == 0) {
      return res["uri"];
    } else {
      throw SystemException(res['reason']);
    }
  }

  Future<String> getPostMessageConnectionURI() async {
    Map res = await _channel.invokeMethod('getPostMessageConnectionURI', {});
    if (res['error'] == 0) {
      return res["uri"];
    } else {
      throw SystemException(res['reason']);
    }
  }

  Future<List> handlePostMessageOpenChannel(String payload) async {
    Map res = await _channel
        .invokeMethod('handlePostMessageOpenChannel', {"payload": payload});

    final peerData = json.decode(res['peer']);
    return [Peer.fromJson(peerData), res['permissionRequestMessage']];
  }

  Future<List> handlePostMessageMessage(
      String extensionPublicKey, String payload) async {
    Map res = await _channel.invokeMethod('handlePostMessageMessage',
        {"extensionPublicKey": extensionPublicKey, "payload": payload});

    if (res['error'] == 0) {
      final response = json.decode(res['response']);
      return [res['tzAddress'], PermissionResponse.fromJson(response)];
    } else {
      switch (res['reason']) {
        case "aborted":
          throw AbortedException();
        default:
          throw SystemException(res['reason']);
      }
    }
  }

  void listen() async {
    await for (Map event in _eventChannel.receiveBroadcastStream()) {
      var params = event['params'];
      switch (event['eventName']) {
        case 'observeRequest':
          final String id = params["id"];
          final String senderID = params["senderID"];
          final String version = params["version"];
          final String originID = params["originID"];
          final String type = params["type"];
          final String? appName = params["appName"];
          final String? icon = params["icon"];

          final request = BeaconRequest(
              id, senderID, version, originID, type, appName, icon);
          switch (type) {
            case "signPayload":
              final String? payload = params["payload"];
              final String? sourceAddress = params["sourceAddress"];
              request.payload = payload;
              request.sourceAddress = sourceAddress;
              break;
            case "operation":
              final List operationsDetails = params["operationDetails"];
              final String? sourceAddress = params["sourceAddress"];

              List<Operation> operations = [];
              operationsDetails.forEach((element) {
                final String? kind = element["kind"];
                final String? storageLimit = element["storageLimit"];
                final String? gasLimit = element["gasLimit"];
                final String? fee = element["fee"];

                if (kind == "origination") {
                  final String balance = element["balance"] ?? "0";
                  final List<dynamic> code = element["code"];
                  final dynamic storage = element["storage"];

                  final operation = OriginationOperation(
                    balance: int.parse(balance),
                    code: code.map((e) => Map<String, dynamic>.from(e)).toList(),
                    storage: storage,
                    customFee: fee != null ? int.parse(fee) : null,
                    customGasLimit:
                        gasLimit != null ? int.parse(gasLimit) : null,
                    customStorageLimit:
                        storageLimit != null ? int.parse(storageLimit) : null,
                  );
                  operations.add(operation);
                } else {
                  final String destination = element["destination"] ?? "";
                  final String amount = element["amount"] ?? "0";
                  final String? entrypoint = element["entrypoint"];
                  final dynamic parameters =
                      json.decode(json.encode(element["parameters"]));

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
              });

              request.operations = operations;
              request.sourceAddress = sourceAddress;
              break;
          }

          handler!.onRequest(request);
          break;
        case "observeEvent":
          switch (params["type"]) {
            case "beaconRequestedPermission":
              final Uint8List data = params["peer"];
              Peer peer = Peer.fromJson(json.decode(utf8.decode(data)));
              handler!.onRequestedPermission(peer);
              break;
            case "beaconLinked":
              final Uint8List data = params["connection"];
              TezosConnection tezosConnection =
                  TezosConnection.fromJson(json.decode(utf8.decode(data)));
              await handler!.onLinked(tezosConnection);
              break;
            case "error":
              break;
            case "userAborted":
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

  Future<void> onLinked(TezosConnection tezosConnection);

  void onAbort();
}

class BeaconRequest {
  final String id;
  final String senderID;
  final String version;
  final String originID;
  final String type;
  final String? appName;
  final String? icon;

  List<Operation>? operations;
  String? payload;
  String? sourceAddress;

  BeaconRequest(this.id, this.senderID, this.version, this.originID, this.type,
      this.appName, this.icon);
}
