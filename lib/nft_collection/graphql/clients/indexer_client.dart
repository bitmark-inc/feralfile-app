import 'dart:async';

import 'package:autonomy_flutter/nft_collection/nft_collection.dart';
import 'package:autonomy_flutter/nft_collection/utils/nft_collection_error.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sentry/sentry.dart';

class IndexerClient {
  IndexerClient(this._baseUrl);

  final String _baseUrl;

  GraphQLClient get client {
    final httpLink = HttpLink('$_baseUrl/v2/graphql');
    final authLink = AuthLink(getToken: _getToken);
    final link = authLink.concat(httpLink);

    return GraphQLClient(
      cache: GraphQLCache(dataIdFromObject: (data) => null),
      link: link,
    );
  }

  Future<dynamic> query({
    required String doc,
    Map<String, dynamic> vars = const {},
    bool withToken = false,
    String? subKey,
  }) async {
    try {
      final options = QueryOptions(
        document: gql(doc),
        variables: vars,
      );

      final result = await client.query(options);
      if (subKey != null) {
        return result.data?[subKey];
      }
      return result.data;
    } catch (e) {
      NftCollection.logger.info('Error querying: $e');
      unawaited(
        Sentry.captureException(
          NFTCollectionClientQueryError(
            query: doc,
            message: 'Failed to query: $e',
            variables: vars,
          ),
        ),
      );
      return null;
    }
  }

  Future<dynamic> mutate({
    required String doc,
    Map<String, dynamic> vars = const {},
    bool withToken = false,
  }) async {
    try {
      final options = MutationOptions(
        document: gql(doc),
        variables: vars,
      );

      final result = await client.mutate(options);
      return result.data;
    } catch (e) {
      return null;
    }
  }

  Future<String> _getToken() async {
    return '';
  }
}
