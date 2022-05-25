//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/model/provenance.dart';
import 'package:autonomy_flutter/util/constants.dart';

class Asset {
  Asset({
    required this.id,
    required this.edition,
    required this.blockchain,
    required this.mintedAt,
    required this.contractType,
    required this.blockchainURL,
    required this.owner,
    required this.thumbnailID,
    required this.projectMetadata,
    required this.lastActivityTime,
    required this.provenance,
  });

  String id;
  int edition;
  String blockchain;
  DateTime mintedAt;
  String contractType;
  String? blockchainURL;
  String owner;
  String thumbnailID;
  ProjectMetadata projectMetadata;
  DateTime lastActivityTime;
  List<Provenance> provenance;

  factory Asset.fromJson(Map<String, dynamic> json, Network network) {
    String? blockchainURL = json["blockchainURL"];

    if (blockchainURL == null || blockchainURL.isEmpty) {
      switch ("${network.rawValue}_${json["blockchain"]}") {
        case "MAINNET_ethereum":
          blockchainURL =
              "https://etherscan.io/address/${json['contractAddress']}";
          break;

        case "TESTNET_ethereum":
          blockchainURL =
              "https://rinkeby.etherscan.io/address/${json['contractAddress']}";
          break;

        case "MAINNET_tezos":
        case "TESTNET_tezos":
          blockchainURL = "https://tzkt.io/${json['contractAddress']}";
          break;

        case "MAINNET_bitmark":
          blockchainURL = "https://registry.bitmark.com/bitmark/${json['id']}";
          break;
        case "TESTNET_bitmark":
          blockchainURL =
              "https://registry.test.bitmark.com/bitmark/${json['id']}";
          break;
      }
    }

    return Asset(
      id: json["indexID"],
      edition: json["edition"],
      blockchain: json["blockchain"],
      mintedAt: DateTime.parse(json["mintedAt"]),
      contractType: json["contractType"],
      blockchainURL: blockchainURL,
      owner: json["owner"],
      thumbnailID: json["thumbnailID"],
      projectMetadata: ProjectMetadata.fromJsonModified(
          json["projectMetadata"], json["thumbnailID"]),
      lastActivityTime: DateTime.parse(json['lastActivityTime']),
      provenance: json["provenance"] != null
          ? List<Provenance>.from(json["provenance"]
              .map((x) => Provenance.fromJson(x, json["indexID"])))
          : [],
    );
  }
}

class ProjectMetadata {
  ProjectMetadata({
    required this.origin,
    required this.latest,
  });

  ProjectMetadataData origin;
  ProjectMetadataData latest;

  factory ProjectMetadata.fromJson(Map<String, dynamic> json) =>
      ProjectMetadata(
        origin: ProjectMetadataData.fromJson(json["origin"]),
        latest: ProjectMetadataData.fromJson(json["latest"]),
      );

  factory ProjectMetadata.fromJsonModified(
          Map<String, dynamic> json, String thumnailID) =>
      ProjectMetadata(
        origin: ProjectMetadataData.fromJson(json["origin"]),
        latest:
            ProjectMetadataData.fromJsonModified(json["latest"], thumnailID),
      );

  Map<String, dynamic> toJson() => {
        "origin": origin.toJson(),
        "latest": latest.toJson(),
      };
}

class ProjectMetadataData {
  ProjectMetadataData({
    required this.artistName,
    required this.artistUrl,
    required this.assetId,
    required this.title,
    required this.description,
    required this.medium,
    required this.maxEdition,
    required this.baseCurrency,
    required this.basePrice,
    required this.source,
    required this.sourceUrl,
    required this.previewUrl,
    required this.thumbnailUrl,
    required this.galleryThumbnailUrl,
    required this.assetData,
    required this.assetUrl,
    required this.artistId,
    required this.originalFileUrl,
  });

  String? artistName;
  String? artistUrl;
  String? assetId;
  String title;
  String? description;
  String? medium;
  int? maxEdition;
  String? baseCurrency;
  double? basePrice;
  String? source;
  String? sourceUrl;
  String previewUrl;
  String thumbnailUrl;
  String? galleryThumbnailUrl;
  String? assetData;
  String? assetUrl;
  String? artistId;
  String? originalFileUrl;

  factory ProjectMetadataData.fromJson(Map<String, dynamic> json) =>
      ProjectMetadataData(
        artistName: json["artistName"],
        artistUrl: json["artistURL"],
        assetId: json["assetID"],
        title: json["title"],
        description: json["description"],
        medium: json["medium"],
        maxEdition: json["maxEdition"],
        baseCurrency: json["baseCurrency"],
        basePrice: json["basePrice"]?.toDouble(),
        source: json["source"],
        sourceUrl: json["sourceURL"],
        previewUrl: json["previewURL"],
        thumbnailUrl: json["thumbnailURL"],
        galleryThumbnailUrl: json["galleryThumbnailURL"],
        assetData: json["assetData"],
        assetUrl: json["assetURL"],
        artistId: json["artistID"],
        originalFileUrl: json["originalFileURL"],
      );

  factory ProjectMetadataData.fromJsonModified(
          Map<String, dynamic> json, String thumbailID) =>
      ProjectMetadataData(
        artistName: json["artistName"],
        artistUrl: json["artistURL"],
        assetId: json["assetID"],
        title: json["title"],
        description: json["description"],
        medium: json["medium"],
        maxEdition: json["maxEdition"],
        baseCurrency: json["baseCurrency"],
        basePrice: json["basePrice"]?.toDouble(),
        source: json["source"],
        sourceUrl: json["sourceURL"],
        previewUrl: _replaceIPFS(json["previewURL"]),
        thumbnailUrl:
            _refineToCloudflareURL(json["thumbnailURL"], thumbailID, "preview"),
        galleryThumbnailUrl: _refineToCloudflareURL(
            json["galleryThumbnailURL"], thumbailID, "thumbnail"),
        assetData: json["assetData"],
        assetUrl: json["assetURL"],
        artistId: json["artistID"],
        originalFileUrl: json["originalFileURL"],
      );

  Map<String, dynamic> toJson() => {
        "artistName": artistName,
        "artistURL": artistUrl,
        "assetID": assetId,
        "title": title,
        "description": description,
        "medium": medium,
        "maxEdition": maxEdition,
        "baseCurrency": baseCurrency,
        "basePrice": basePrice,
        "source": source,
        "sourceURL": sourceUrl,
        "previewURL": previewUrl,
        "thumbnailURL": thumbnailUrl,
        "galleryThumbnailURL": galleryThumbnailUrl,
        "assetData": assetData,
        "assetURL": assetUrl,
        "artistID": artistId,
        "originalFileURL": originalFileUrl,
      };
}

String _replaceIPFS(String url) {
  if (url.startsWith(DEFAULT_IPFS_PREFIX)) {
    return url.replaceRange(
        0, DEFAULT_IPFS_PREFIX.length, CLOUDFLARE_IPFS_PREFIX);
  }
  return url;
}

String _refineToCloudflareURL(String url, String thumbnailID, String variant) {
  return thumbnailID.isEmpty
      ? _replaceIPFS(url)
      : CLOUDFLAREIMAGEURLPREFIX + thumbnailID + "/" + variant;
}
