//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/wc_peer_meta.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:collection/collection.dart';
import 'package:tezart/tezart.dart';

abstract class ConnectionRequest {
  bool get isWalletConnect2 => false;

  bool get isAutonomyConnect => false;

  bool get isBeaconConnect => false;

  get id;

  String? get name;

  String? get url;
}

class BeaconRequest extends ConnectionRequest {
  final String _id;
  final String? senderID;
  final String? version;
  final String? originID;
  final String? type;
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
    this._id, {
    this.senderID,
    this.version,
    this.originID,
    this.type,
    this.appName,
    this.icon,
    this.wc2Topic,
    this.operations,
    this.payload,
    this.sourceAddress,
  });
}

class Wc2Proposal extends ConnectionRequest {
  Wc2Proposal(
    this._id, {
    required this.proposer,
    required this.requiredNamespaces,
  });

  @override
  bool get isWalletConnect2 => !_isAutonomyConnect();

  @override
  bool get isAutonomyConnect => _isAutonomyConnect();

  bool _isAutonomyConnect() {
    final proposalMethods =
        requiredNamespaces.values.map((e) => e.methods).flattened.toSet();
    final unsupportedMethods =
        proposalMethods.difference(Wc2Service.autonomyMethods);
    return unsupportedMethods.isEmpty;
  }

  AppMetadata proposer;
  Map<String, Wc2Namespace> requiredNamespaces;
  final String _id;

  @override
  get id => _id;

  @override
  String? get name => proposer.name;

  @override
  String? get url => proposer.url;
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
