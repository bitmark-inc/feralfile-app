//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:json_annotation/json_annotation.dart';

part 'ff_account.g.dart';

@JsonSerializable()
class FFAccount {
  @JsonKey(name: "ID", defaultValue: '')
  String id;
  String alias;
  String location;
  WyreWallet? wyreWallet;
  Map<String, String>? vaultAddresses;

  FFAccount(
      {required this.id,
      required this.alias,
      required this.location,
      required this.wyreWallet,
      required this.vaultAddresses});

  factory FFAccount.fromJson(Map<String, dynamic> json) =>
      _$FFAccountFromJson(json);

  Map<String, dynamic> toJson() => _$FFAccountToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

  String? get ethereumAddress {
    return vaultAddresses?['ethereum'];
  }

  String? get tezosAddress {
    return vaultAddresses?['tezos'];
  }
}

@JsonSerializable()
class WyreWallet {
  Map<String, double> availableBalances;

  WyreWallet({
    required this.availableBalances,
  });

  factory WyreWallet.fromJson(Map<String, dynamic> json) =>
      _$WyreWalletFromJson(json);

  Map<String, dynamic> toJson() => _$WyreWalletToJson(this);
}

@JsonSerializable()
class Exhibition {
  final String title;

  @JsonKey(name: "cover_uri")
  final String coverUri;

  @JsonKey(name: "thumbnail_cover_uri")
  final String thumbnailCoverUri;

  @JsonKey(name: "airdrop_info")
  final AirdropInfo airdrop;

  Exhibition(this.airdrop, this.title, this.coverUri, this.thumbnailCoverUri);

  factory Exhibition.fromJson(Map<String, dynamic> json) =>
      _$ExhibitionFromJson(json);

  Map<String, dynamic> toJson() => _$ExhibitionToJson(this);
}

@JsonSerializable()
class AirdropInfo {
  final String contract;
  final int leftEdition;

  AirdropInfo(this.contract, this.leftEdition);

  factory AirdropInfo.fromJson(Map<String, dynamic> json) =>
      _$AirdropInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AirdropInfoToJson(this);
}

@JsonSerializable()
class TokenClaimResponse {
  final String contract;
  final String tokenId;

  TokenClaimResponse(this.contract, this.tokenId);

  factory TokenClaimResponse.fromJson(Map<String, dynamic> json) =>
      _$TokenClaimResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TokenClaimResponseToJson(this);
}
