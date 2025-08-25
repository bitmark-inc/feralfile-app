import 'package:autonomy_flutter/common/environment.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:autonomy_flutter/nft_collection/nft_collection.dart';

class ArtblocksClient {
  ArtblocksClient();

  GraphQLClient get client {
    final httpLink = HttpLink(Environment.artblocksGraphQLURL);

    return GraphQLClient(
      cache: GraphQLCache(dataIdFromObject: (data) => null),
      link: httpLink,
    );
  }

  Future<dynamic> query({
    required String doc,
    Map<String, dynamic> vars = const {},
  }) async {
    try {
      final options = QueryOptions(
        document: gql(doc),
        variables: vars,
      );

      final result = await client.query(options);

      if (result.hasException) {
        NftCollection.logger
            .info('Error querying Artblocks: ${result.exception.toString()}');
        return null;
      }
      return result.data;
    } catch (e) {
      NftCollection.logger.info('Error querying Artblocks: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> queryProjectMetadata({
    required String contractAddress,
    required String tokenId,
  }) async {
    const String doc = r'''
      query GetToken(
          $contract_address: String!
          $token_id: String!
      ) {
          projects_metadata(
              where: {
                  tokens: {
                      token_id: { _eq: $token_id }
                      contract_address: { _eq: $contract_address }
                  }
              }
          ) {
              name
              description
              website
              artist_name
              artist_address
          }
      }
    ''';

    try {
      final options = QueryOptions(
        document: gql(doc),
        variables: {
          'contract_address': contractAddress,
          'token_id': tokenId,
        },
      );

      final result = await client.query(options);

      if (result.hasException) {
        NftCollection.logger.info(
            'Error querying Artblocks project metadata: ${result.exception.toString()}');
        return null;
      }
      return result.data;
    } catch (e) {
      NftCollection.logger
          .info('Error querying Artblocks project metadata: $e');
      return null;
    }
  }
}
