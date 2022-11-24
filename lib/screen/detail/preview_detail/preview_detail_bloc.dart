//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_state.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:nft_collection/database/dao/asset_token_dao.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class ArtworkPreviewDetailBloc
    extends AuBloc<ArtworkPreviewDetailEvent, ArtworkPreviewDetailState> {
  final AssetTokenDao _assetTokenDao;
  final EthereumService _ethereumService;

  ArtworkPreviewDetailBloc(this._assetTokenDao, this._ethereumService)
      : super(ArtworkPreviewDetailLoadingState()) {
    on<ArtworkPreviewDetailGetAssetTokenEvent>((event, emit) async {
      final asset = await _assetTokenDao.findAssetTokenByIdAndOwner(
          event.identity.id, event.identity.owner);
      String? overriddenHtml;
      if (asset != null && asset.isFeralfileFrame == true) {
        overriddenHtml = await _fetchFeralFileFramePreview(asset);
      }
      emit(ArtworkPreviewDetailLoadedState(
          asset: asset, overriddenHtml: overriddenHtml));
    });

    on<ArtworkFeedPreviewDetailGetAssetTokenEvent>((event, emit) async {
      final asset = event.token;
      String? overriddenHtml;
      if (asset.isFeralfileFrame == true) {
        overriddenHtml = await _fetchFeralFileFramePreview(asset);
      }
      emit(ArtworkPreviewDetailLoadedState(
          asset: asset, overriddenHtml: overriddenHtml));
    });
  }

  Future<String?> _fetchFeralFileFramePreview(AssetToken token) async {
    if (token.contractAddress == null) return "";

    try {
      final contract = EthereumAddress.fromHex(token.contractAddress!);
      final data = hexToBytes("c87b56dd${token.tokenIdHex()}");

      final metadata =
          await _ethereumService.getFeralFileTokenMetadata(contract, data);

      final tokenMetadata = json.decode(_decodeBase64WithPrefix(metadata));
      return _decodeBase64WithPrefix(tokenMetadata["animation_url"]);
    } catch (e) {
      log.warning(
          "[ArtworkPreviewDetailBloc] _fetchFeralFileFramePreview failed - $e");
      return null;
    }
  }

  String _decodeBase64WithPrefix(String message) =>
      utf8.decode(base64.decode(message.split("base64,").last));
}
