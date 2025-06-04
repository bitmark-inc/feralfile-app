import 'dart:async';

import 'package:autonomy_flutter/nft_collection/models/asset_token.dart';
import 'package:autonomy_flutter/nft_collection/models/pending_tx_params.dart';
import 'package:autonomy_flutter/nft_collection/services/tokens_service.dart';
import 'package:widgetbook_workspace/mock_data/mock_asset_token.dart';

class MockTokensService extends TokensService {
  @override
  Future<void> fetchTokensForAddresses(List<String> addresses) async {
    // Mock implementation
  }

  @override
  Future<List<AssetToken>> fetchManualTokens(List<String> indexerIds) async {
    return MockAssetToken.all.where((e) => indexerIds.contains(e.id)).toList();
  }

  @override
  Future<void> setCustomTokens(List<AssetToken> assetTokens) async {
    // Mock implementation
  }

  @override
  Future<Stream<List<AssetToken>>> refreshTokensInIsolate(
    Map<int, List<String>> addresses,
  ) async {
    return Stream.value([]);
  }

  @override
  Future<void> reindexAddresses(List<String> addresses) async {
    // Mock implementation
  }

  @override
  bool get isRefreshAllTokensListen => false;

  @override
  Future<void> purgeCachedGallery() async {
    // Mock implementation
  }

  @override
  Future<void> postPendingToken(PendingTxParams params) async {
    // Mock implementation
  }
}
