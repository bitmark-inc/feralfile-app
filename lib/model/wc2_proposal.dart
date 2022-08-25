//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

class Wc2Proposal {
  Wc2Proposal({
    required this.proposer,
    required this.requiredNamespaces,
    required this.id,
  });

  AppMetadata proposer;
  Map<String, Wc2Namespace> requiredNamespaces;
  String id;
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
