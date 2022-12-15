//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:json_annotation/json_annotation.dart';

part 'p2p_peer.g.dart';

@JsonSerializable()
class P2PPeer {
  final String id;
  final String name;
  final String publicKey;
  final String relayServer;
  final String version;
  final String? icon;
  final String? appURL;

  P2PPeer(this.id, this.name, this.publicKey, this.relayServer, this.version,
      this.icon, this.appURL);

  factory P2PPeer.fromJson(Map<String, dynamic> json) =>
      _$P2PPeerFromJson(json);

  Map<String, dynamic> toJson() => _$P2PPeerToJson(this);
}
