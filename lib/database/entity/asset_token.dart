//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/model/asset.dart';
import 'package:autonomy_flutter/model/provenance.dart';
import 'package:floor/floor.dart';
import 'package:libauk_dart/libauk_dart.dart';

@entity
class AssetToken {
  String? artistName;
  String? artistURL;
  String? artistID;
  String? assetData;
  String? assetID;
  String? assetURL;
  double? basePrice;
  String? baseCurrency;
  String blockchain;
  String? contractType;
  String? tokenId;
  String? contractAddress;
  String? blockchainURL;
  String? desc;
  int edition;
  @primaryKey
  String id;
  int? maxEdition;
  String? medium;
  String? mimeType;
  String? mintedAt;
  String? previewURL;
  String? source;
  String? sourceURL;
  String? thumbnailURL;
  String? galleryThumbnailURL;
  String title;
  String? ownerAddress;
  DateTime lastActivityTime;
  int? hidden;
  @ignore
  List<Provenance>? provenances;

  AssetToken({
    required this.artistName,
    required this.artistURL,
    required this.artistID,
    required this.assetData,
    required this.assetID,
    required this.assetURL,
    required this.basePrice,
    required this.baseCurrency,
    required this.blockchain,
    required this.contractType,
    required this.tokenId,
    required this.contractAddress,
    required this.blockchainURL,
    required this.desc,
    required this.edition,
    required this.id,
    required this.maxEdition,
    required this.medium,
    required this.mimeType,
    required this.mintedAt,
    required this.previewURL,
    required this.source,
    required this.sourceURL,
    required this.thumbnailURL,
    required this.galleryThumbnailURL,
    required this.title,
    required this.ownerAddress,
    required this.lastActivityTime,
    this.hidden,
    this.provenances,
  });

  factory AssetToken.fromAsset(Asset asset) => AssetToken(
        artistName: asset.projectMetadata.latest.artistName,
        artistURL: asset.projectMetadata.latest.artistUrl,
        artistID: asset.projectMetadata.latest.artistId,
        assetData: asset.projectMetadata.latest.assetData,
        assetID: asset.projectMetadata.latest.assetId,
        assetURL: asset.projectMetadata.latest.assetUrl,
        basePrice: asset.projectMetadata.latest.basePrice,
        baseCurrency: asset.projectMetadata.latest.baseCurrency,
        blockchain: asset.blockchain,
        contractType: asset.contractType,
        tokenId: asset.tokenId,
        contractAddress: asset.contractAddress,
        blockchainURL: asset.blockchainURL,
        desc: asset.projectMetadata.latest.description,
        edition: asset.edition,
        id: asset.id,
        maxEdition: asset.projectMetadata.latest.maxEdition,
        medium: asset.projectMetadata.latest.medium,
        mimeType: asset.projectMetadata.latest.mimeType,
        mintedAt: asset.mintedAt.toIso8601String(),
        previewURL: asset.projectMetadata.latest.previewUrl,
        source: asset.projectMetadata.latest.source,
        sourceURL: asset.projectMetadata.latest.sourceUrl,
        thumbnailURL: asset.projectMetadata.latest.thumbnailUrl,
        galleryThumbnailURL: asset.projectMetadata.latest.galleryThumbnailUrl,
        title: asset.projectMetadata.latest.title,
        ownerAddress: asset.owner,
        lastActivityTime: asset.lastActivityTime,
        provenances: asset.provenance,
      );

  bool isHidden() => hidden == 1;

  Future<WalletStorage?> getOwnerWallet() async {
    if (contractAddress == null || tokenId == null) return null;
    if (!(blockchain == "ethereum" && contractType == "erc721") &&
        !(blockchain == "tezos" && contractType == "fa2")) return null;

    //check asset is able to send
    final personas = await injector<CloudDatabase>().personaDao.getPersonas();

    WalletStorage? wallet;
    for (final persona in personas) {
      final address;
      if (blockchain == "ethereum") {
        address = await persona.wallet().getETHAddress();
      } else {
        address = (await persona.wallet().getTezosWallet()).address;
      }
      if (address == ownerAddress) {
        wallet = persona.wallet();
        break;
      }
    }
    return wallet;
  }
}
