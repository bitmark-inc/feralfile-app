import 'package:autonomy_flutter/nft_collection/graphql/clients/indexer_client.dart';
import 'package:autonomy_flutter/nft_collection/graphql/model/get_list_collection.dart';
import 'package:autonomy_flutter/nft_collection/graphql/model/get_list_token_configurations.dart';
import 'package:autonomy_flutter/nft_collection/graphql/model/get_list_tokens.dart';
import 'package:autonomy_flutter/nft_collection/graphql/model/identity.dart';
import 'package:autonomy_flutter/nft_collection/graphql/queries/collection_queries.dart';
import 'package:autonomy_flutter/nft_collection/graphql/queries/queries.dart';

class MockIndexerClient extends IndexerClient {
  MockIndexerClient() : super('mock_url');

  @override
  Future<dynamic> query({
    required String doc,
    Map<String, dynamic> vars = const {},
    bool withToken = false,
    String? subKey,
  }) async {
    if (doc == getTokens) {
      return {
        'tokens': [
          {
            'id': 'mock_token_id',
            'name': 'Mock Token',
            'description': 'Mock Description',
            'thumbnailURL': 'https://example.com/thumbnail.jpg',
            'previewURL': 'https://example.com/preview.jpg',
            'owner': 'mock_owner',
            'blockchain': 'mock_blockchain',
            'contractAddress': 'mock_contract_address',
            'tokenID': 'mock_token_id',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }
        ]
      };
    } else if (doc == identity) {
      return {
        'identity': {
          'accountNumber': 'mock_account',
          'blockchain': 'mock_blockchain',
          'name': 'Mock Name'
        }
      };
    } else if (doc == collectionQuery) {
      return {
        'collections': [
          {
            'id': 'mock_collection_id',
            'name': 'Mock Collection',
            'description': 'Mock Description',
            'imageURL': 'https://example.com/image.jpg',
            'creator': 'mock_creator',
            'blockchain': 'mock_blockchain',
            'contracts': ['mock_contract'],
            'published': true,
            'source': 'mock_source',
            'sourceURL': 'https://example.com/source',
            'projectURL': 'https://example.com/project',
            'thumbnailURL': 'https://example.com/thumbnail.jpg',
            'lastUpdatedTime': DateTime.now().toIso8601String(),
            'lastActivityTime': DateTime.now().toIso8601String(),
            'createdAt': DateTime.now().toIso8601String(),
          }
        ]
      };
    } else if (doc == getColectionTokenQuery) {
      return {
        'tokens': [
          {
            'id': 'mock_token_id',
            'name': 'Mock Token',
            'description': 'Mock Description',
            'thumbnailURL': 'https://example.com/thumbnail.jpg',
            'previewURL': 'https://example.com/preview.jpg',
            'owner': 'mock_owner',
            'blockchain': 'mock_blockchain',
            'contractAddress': 'mock_contract_address',
            'tokenID': 'mock_token_id',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }
        ]
      };
    } else if (doc == getTokenConfigurations) {
      return {
        'tokenConfigurations': [
          {
            'tokenId': 'mock_token_id',
            'displaySettings': {
              'showArtistName': true,
              'showTitle': true,
              'showDescription': true,
            }
          }
        ]
      };
    }
    return null;
  }
}
