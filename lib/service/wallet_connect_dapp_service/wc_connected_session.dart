//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// part of 'wallet_connect_dapp_service.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:wallet_connect/wallet_connect.dart';
part 'wc_connected_session.g.dart';

@JsonSerializable()
class WCConnectedSession {
  final WCSessionStore sessionStore;
  final List<String> accounts;

  WCConnectedSession({
    required this.sessionStore,
    required this.accounts,
  });

  factory WCConnectedSession.fromJson(Map<String, dynamic> json) =>
      _$WCConnectedSessionFromJson(json);
  Map<String, dynamic> toJson() => _$WCConnectedSessionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
