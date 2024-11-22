//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:json_annotation/json_annotation.dart';

part 'ff_account.g.dart';

@JsonSerializable()
class FFContract {
  final String name;
  final String blockchainType;
  final String address;

  FFContract(
    this.name,
    this.blockchainType,
    this.address,
  );

  factory FFContract.fromJson(Map<String, dynamic> json) =>
      _$FFContractFromJson(json);

  Map<String, dynamic> toJson() => _$FFContractToJson(this);
}

@JsonSerializable()
class FeralfileError {
  final int code;
  final String message;

  FeralfileError(
    this.code,
    this.message,
  );

  factory FeralfileError.fromJson(Map<String, dynamic> json) =>
      _$FeralfileErrorFromJson(json);

  Map<String, dynamic> toJson() => _$FeralfileErrorToJson(this);

  @override
  String toString() => 'FeralfileError{code: $code, message: $message}';
}

@JsonSerializable()
class ResaleResponse {
  final FeralFileResaleInfo result;

  ResaleResponse(this.result);

  factory ResaleResponse.fromJson(Map<String, dynamic> json) =>
      _$ResaleResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ResaleResponseToJson(this);
}

@JsonSerializable()
class FeralFileResaleInfo {
  final String exhibitionID;
  final String saleType;
  final double platform;
  final double artist;
  final double seller;
  final double curator;
  final double partner;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeralFileResaleInfo(
      this.exhibitionID,
      this.saleType,
      this.platform,
      this.artist,
      this.seller,
      this.curator,
      this.partner,
      this.createdAt,
      this.updatedAt);

  factory FeralFileResaleInfo.fromJson(Map<String, dynamic> json) =>
      _$FeralFileResaleInfoFromJson(json);

  Map<String, dynamic> toJson() => _$FeralFileResaleInfoToJson(this);
}

class FileAssetMetadata {
  final String urlOverwrite;

  FileAssetMetadata({required this.urlOverwrite});

  // from Json method
  factory FileAssetMetadata.fromJson(Map<String, dynamic> json) =>
      FileAssetMetadata(urlOverwrite: json['urlOverwrite']);

  // to Json method
  Map<String, dynamic> toJson() => {
        'urlOverwrite': urlOverwrite,
      };
}

class FileInfo {
  final String? filename;
  final String uri;
  final String status;
  final String? version;
  final FileAssetMetadata? metadata;
  final String? createdAt;
  final String? updatedAt;

  FileInfo({
    required this.uri,
    required this.status,
    this.filename,
    this.version,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  // from Json method
  factory FileInfo.fromJson(Map<String, dynamic> json) => FileInfo(
        filename: json['filename'],
        uri: json['uri'],
        status: json['status'],
        version: json['version'],
        metadata: json['metadata'] == null ||
                (json['metadata'] as Map<String, dynamic>).isEmpty ||
                (json['metadata'] as Map<String, dynamic>)['urlOverwrite'] ==
                    null
            ? null
            : FileAssetMetadata.fromJson(
                json['metadata'] as Map<String, dynamic>),
        createdAt: json['createdAt'],
        updatedAt: json['updatedAt'],
      );

  // to Json method
  Map<String, dynamic> toJson() => {
        'filename': filename,
        'uri': uri,
        'status': status,
        'version': version,
        'metadata': metadata?.toJson(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
