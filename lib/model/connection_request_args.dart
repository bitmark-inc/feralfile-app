//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:tezart/tezart.dart';
import 'package:wallet_connect/wallet_connect.dart';

abstract class ConnectionRequest {
  bool get isWCconnect => false;
  bool get isWC2connect => false;
  bool get isBeaconConnect => false;

  get id;
  String? get name;
  String? get url;
}

class WCConnectPageArgs extends ConnectionRequest {
  final int _id;
  final WCPeerMeta peerMeta;

  @override
  bool get isWCconnect => true;

  WCConnectPageArgs(this._id, this.peerMeta);

  @override
  get id => _id;

  @override
  String? get name => peerMeta.name;

  @override
  String? get url => peerMeta.url;
}

class BeaconRequest extends ConnectionRequest {
  final String _id;
  final String senderID;
  final String version;
  final String originID;
  final String type;
  final String? appName;
  final String? icon;

  List<Operation>? operations;
  String? payload;
  String? sourceAddress;

  String? wc2Topic;

  @override
  bool get isBeaconConnect => true;

  @override
  get id => _id;

  @override
  String? get name => appName;

  @override
  String? get url => null;

  BeaconRequest(
    this._id,
    this.senderID,
    this.version,
    this.originID,
    this.type,
    this.appName,
    this.icon, {
    this.wc2Topic,
  });
}

class Wc2Proposal extends ConnectionRequest {
  Wc2Proposal(
    this._id, {
    required this.proposer,
    required this.requiredNamespaces,
  });

  @override
  bool get isWC2connect => true;

  AppMetadata proposer;
  Map<String, Wc2Namespace> requiredNamespaces;
  final String _id;

  @override
  get id => _id;

  @override
  String? get name => proposer.name;

  @override
  String? get url => proposer.name;
}

class AppMetadata {
  AppMetadata({
    required this.icons,
    required this.name,
    required this.url,
    required this.description,
  });

  List<String> icons;
  String name;
  String url;
  String description;

  factory AppMetadata.fromJson(Map<String, dynamic> json) => AppMetadata(
        icons: List<String>.from(json["icons"].map((x) => x)),
        name: json["name"],
        url: json["url"],
        description: json["description"],
      );

  Map<String, dynamic> toJson() => {
        "icons": List<dynamic>.from(icons.map((x) => x)),
        "name": name,
        "url": url,
        "description": description,
      };

  WCPeerMeta toWCPeerMeta() {
    return WCPeerMeta(
      name: name,
      url: url,
      description: description,
      icons: icons,
    );
  }
}

class Wc2Namespace {
  Wc2Namespace({
    required this.chains,
    required this.methods,
    required this.events,
  });

  List<String> chains;
  List<String> methods;
  List<dynamic> events;

  factory Wc2Namespace.fromJson(Map<String, dynamic> json) => Wc2Namespace(
        chains: List<String>.from(json["chains"].map((x) => x)),
        methods: List<String>.from(json["methods"].map((x) => x)),
        events: List<dynamic>.from(json["events"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "chains": List<dynamic>.from(chains.map((x) => x)),
        "methods": List<dynamic>.from(methods.map((x) => x)),
        "events": List<dynamic>.from(events.map((x) => x)),
      };
}
