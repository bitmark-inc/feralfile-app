//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/dao.dart';
import 'package:autonomy_flutter/nft_collection/graphql/model/get_list_tokens.dart';
import 'package:autonomy_flutter/nft_collection/models/asset_token.dart';
import 'package:autonomy_flutter/nft_collection/services/indexer_service.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_state.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class ArtworkPreviewDetailBloc
    extends AuBloc<ArtworkPreviewDetailEvent, ArtworkPreviewDetailState> {
  ArtworkPreviewDetailBloc(
    this._assetTokenDao,
    this._ethereumService,
    this._indexerService,
    this._assetDao,
  ) : super(ArtworkPreviewDetailLoadingState()) {
    on<ArtworkPreviewDetailGetAssetTokenEvent>((event, emit) async {
      AssetToken? assetToken;

      if (event.useIndexer) {
        final request = QueryListTokensRequest(
          ids: [event.identity.id],
        );
        final tokens = await _indexerService.getNftTokens(request);
        if (tokens.isNotEmpty) {
          assetToken = tokens.first;
        }
      } else {
        assetToken = await _assetTokenDao.findAssetTokenByIdAndOwner(
          event.identity.id,
          event.identity.owner,
        );
      }
      String? overriddenHtml;
      if (assetToken != null && assetToken.isFeralfileFrame == true) {
        overriddenHtml = await _fetchFeralFileFramePreview(assetToken);
      }

      if (assetToken != null &&
          assetToken.asset != null &&
          (assetToken.mimeType?.isEmpty ?? true)) {
        final uri = Uri.tryParse(assetToken.previewURL ?? '');
        if (uri != null) {
          try {
            final res = await http
                .head(uri)
                .timeout(const Duration(milliseconds: 10000));
            assetToken.asset!.mimeType = res.headers['content-type'];
            unawaited(_assetDao.updateAsset(assetToken.asset!));
          } catch (error) {
            log.info(
              'ArtworkPreviewDetailGetAssetTokenEvent: preview url error',
              error,
            );
          }
        }
      }
      emit(
        ArtworkPreviewDetailLoadedState(
          assetToken: assetToken,
          overriddenHtml: overriddenHtml,
        ),
      );
    });

    on<ArtworkFeedPreviewDetailGetAssetTokenEvent>((event, emit) async {
      await Future.delayed(const Duration(milliseconds: 500)); // Delay 0.5s
      final asset = event.assetToken;
      String? overriddenHtml;
      if (asset.isFeralfileFrame == true) {
        overriddenHtml = await _fetchFeralFileFramePreview(asset);
      }

      emit(
        ArtworkPreviewDetailLoadedState(
          assetToken: asset,
          overriddenHtml: overriddenHtml,
        ),
      );
    });
  }

  final AssetTokenDao _assetTokenDao;
  final EthereumService _ethereumService;
  final NftIndexerService _indexerService;
  final AssetDao _assetDao;

  Future<String?> _fetchFeralFileFramePreview(AssetToken token) async {
    if (token.contractAddress == null) return '';

    try {
      final contract = EthereumAddress.fromHex(token.contractAddress!);
      final data = hexToBytes('c87b56dd${token.tokenIdHex()}');

      final metadata =
          await _ethereumService.getFeralFileTokenMetadata(contract, data);

      final tokenMetadata = json.decode(_decodeBase64WithPrefix(metadata));
      return _decodeBase64WithPrefix(tokenMetadata['animation_url'] as String);
    } catch (e) {
      log.warning(
        '[ArtworkPreviewDetailBloc] _fetchFeralFileFramePreview failed - $e',
      );
      return null;
    }
  }

  String _decodeBase64WithPrefix(String message) =>
      utf8.decode(base64.decode(message.split('base64,').last));
}
