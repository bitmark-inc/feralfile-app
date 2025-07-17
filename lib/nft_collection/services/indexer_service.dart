import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/nft_collection/data/api/indexer_api.dart';
import 'package:autonomy_flutter/nft_collection/graphql/clients/indexer_client.dart';
import 'package:autonomy_flutter/nft_collection/graphql/model/get_list_collection.dart';
import 'package:autonomy_flutter/nft_collection/graphql/model/get_list_token_configurations.dart';
import 'package:autonomy_flutter/nft_collection/graphql/model/get_list_tokens.dart';
import 'package:autonomy_flutter/nft_collection/graphql/model/identity.dart';
import 'package:autonomy_flutter/nft_collection/graphql/queries/collection_queries.dart';
import 'package:autonomy_flutter/nft_collection/graphql/queries/queries.dart';
import 'package:autonomy_flutter/nft_collection/models/asset_token.dart';
import 'package:autonomy_flutter/nft_collection/models/identity.dart';
import 'package:autonomy_flutter/nft_collection/models/user_collection.dart';
import 'package:autonomy_flutter/nft_collection/services/artblocks_service.dart';
import 'package:autonomy_flutter/screen/bloc/artist_artwork_display_settings/artist_artwork_display_setting_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_item.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';

class IndexerService {
  IndexerService(this._client, this._indexerApi);

  final IndexerClient _client;
  final IndexerApi _indexerApi;

  Future<List<AssetToken>> getNftTokens(QueryListTokensRequest request) async {
    final vars = request.toJson();
    final result = await _client.query(
      doc: getTokens,
      vars: vars,
    );
    if (result == null) {
      return [];
    }
    final data = QueryListTokensResponse.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
    final assetTokens = data.tokens;
    // missing artist assetToken
    final missingArtistAssetTokens = assetTokens.where((token) {
      final artistAddress = token.asset?.artistID;
      return artistAddress == '0x0000000000000000000000000000000000000000';
    }).toList();
    if (missingArtistAssetTokens.isEmpty) {
      return assetTokens;
    }
    final List<AssetToken> newAssetTokens = assetTokens
      ..removeWhere(missingArtistAssetTokens.contains);
    for (final assetToken in missingArtistAssetTokens) {
      final asset = assetToken.asset;
      if (asset == null) {
        newAssetTokens.add(assetToken);
        continue;
      }
      final artblockArtist = await injector<ArtBlockService>().getArtistByToken(
          contractAddress: assetToken.contractAddress!.toLowerCase(),
          tokenId: assetToken.tokenId!);
      if (artblockArtist == null) {
        newAssetTokens.add(assetToken);
        continue;
      }
      final newAsset = asset.copyWith(
          artistID: artblockArtist.address, artistName: artblockArtist.name);
      newAssetTokens.add(assetToken.copyWith(asset: newAsset));
    }
    // sort the newAssetToken to match with assetTokens
    newAssetTokens.sort((a, b) {
      final aIndex = assetTokens.indexOf(a);
      final bIndex = assetTokens.indexOf(b);
      return aIndex.compareTo(bIndex);
    });
    return newAssetTokens;
  }

  Future<Identity> getIdentity(QueryIdentityRequest request) async {
    final vars = request.toJson();
    final result = await _client.query(
      doc: identity,
      vars: vars,
    );
    if (result == null) {
      return Identity('', '', '');
    }
    final data = QueryIdentityResponse.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
    return data.identity;
  }

  Future<List<UserCollection>> getUserCollections(String address) async {
    return _indexerApi.getCollection(address, 100);
  }

  Future<List<UserCollection>> getCollectionsByAddresses(
    List<String> addresses,
  ) async {
    final vars = {'creators': addresses, 'size': 100, 'offset': 0};
    final res = await _client.query(doc: collectionQuery, vars: vars);
    final data = QueryListCollectionResponse.fromJson(
      Map<String, dynamic>.from(res as Map),
    );
    return data.collections;
  }

  Future<List<AssetToken>> getCollectionListToken(String collectionId) async {
    final res = await _client.query(
      doc: getColectionTokenQuery,
      vars: {'collectionID': collectionId, 'offset': 0, 'size': 100},
    );
    final data =
        QueryListTokensResponse.fromJson(Map<String, dynamic>.from(res as Map));
    return data.tokens;
  }

  Future<ArtistDisplaySetting?> getTokenConfiguration(String tokenId) async {
    final response = await _client.query(
      doc: getTokenConfigurations,
      vars: {'tokenId': tokenId},
    );

    if (response == null) {
      return null;
    }

    final data = QueryListTokenConfigurationsResponse.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
    return data.tokenConfigurations.firstOrNull;
  }

  Future<List<AssetToken>> getAssetTokens(List<DP1Item> items) async {
    final indexIds =
        items.map((item) => item.indexId).whereType<String>().toList();
    final assetTokens = await getNftTokens(
      QueryListTokensRequest(ids: indexIds),
    );
    return List<AssetToken>.from(assetTokens).toList();
  }
}
