import 'dart:convert';

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

    final String id = res["id"];
    final String name = res["name"];
    final String publicKey = res["publicKey"];
    final String relayServer = res["relayServer"];
    final String version = res["version"];
    final String icon = res["icon"];
    final String appURL = res["appURL"];

    return P2PPeer(id, name, publicKey, relayServer, version, icon, appURL);
  }

  Future permissionResponse(String id, String? publicKey) async {
    await _channel.invokeMethod('response', {"id": id, "publicKey": publicKey});
  }

  Future signResponse(String id, String? signature) async {
    await _channel.invokeMethod('response', {"id": id, "signature": signature});
  }

  Future operationResponse(String id, String? txHash) async {
    await _channel.invokeMethod('response', {"id": id, "txHash": txHash});
  }

  void listen() async {
    await for (Map event in _eventChannel.receiveBroadcastStream()) {
      var params = event['params'];
      switch (event['eventName']) {
        case 'observeRequest':
          final String id = params["id"];
          final String blockchainIdentifier = params["blockchainIdentifier"];
          final String senderID = params["senderID"];
          final String version = params["version"];
          final String originID = params["originID"];
          final String type = params["type"];
          final String? appName = params["appName"];
          final String? icon = params["icon"];

          final request = BeaconRequest(id, blockchainIdentifier, senderID,
              version, originID, type, appName, icon);
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

              List<TransactionOperation> operations = [];
              operationsDetails.forEach((element) {
                print(element["parameters"]);

                final String destination = element["destination"] ?? "";
                final String amount = element["amount"] ?? "0";
                final String? entrypoint = element["entrypoint"];
                final Map<String, dynamic> parameters = json.decode(json.encode(element["parameters"]));

                print(parameters.runtimeType);

                operations.add(TransactionOperation(
                  amount: int.parse(amount),
                  destination: destination,
                  entrypoint: entrypoint,
                  params: parameters,
                ));
              });

              request.operations = operations;
              request.sourceAddress = sourceAddress;
              break;
          }

          handler!.onRequest(request);
          break;
      }
    }
  }
}

abstract class BeaconHandler {
  void onRequest(BeaconRequest request);
}

class BeaconRequest {
  final String id;
  final String blockchainIdentifier;
  final String senderID;
  final String version;
  final String originID;
  final String type;
  final String? appName;
  final String? icon;

  List<TransactionOperation>? operations;
  String? payload;
  String? sourceAddress;

  BeaconRequest(this.id, this.blockchainIdentifier, this.senderID, this.version,
      this.originID, this.type, this.appName, this.icon);
}

class P2PPeer {
  final String id;
  final String name;
  final String publicKey;
  final String relayServer;
  final String version;
  final String icon;
  final String appURL;

  P2PPeer(this.id, this.name, this.publicKey, this.relayServer, this.version,
      this.icon, this.appURL);
}