import 'dart:async';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sentry/sentry.dart';

abstract class DomainService {
  Future<String?> getAddress(String domain);

  Future<String?> getEthAddress(String domain);

  Future<String?> getTezosAddress(String domain);
}

class DomainServiceImpl implements DomainService {
  static final String _addressEndpoint = Environment.domainResolverUrl;

  static const String _addressQuery = '''
    query {
      lookup(inputs: [
        { chain: "<chain>", name: "<var>", skipCache: true },
      ]) {
        chain
        name
        address
        error
      }
    }
  ''';

  static const String _subKey = 'lookup';

  static GraphClient get _ensClient => GraphClient(_addressEndpoint);

  Future<String?> _getAddress(String domain, String chain) async {
    try {
      log.info('Getting address for $domain');
      final result = await _ensClient.query(
        doc: _addressQuery
            .replaceFirst('<var>', domain)
            .replaceFirst('<chain>', chain),
        subKey: _subKey,
      ) as List?;
      if (result == null || result.isEmpty) {
        return null;
      }
      final address = result.first['address'] as String?;
      log.info('Address for $domain: $address');
      return address;
    } catch (e) {
      log.info('Error getting address for $domain: $e');
      unawaited(
        Sentry.captureException(
          '[DomainService] Error getting address for $domain: $e',
        ),
      );
      return null;
    }
  }

  @override
  Future<String?> getEthAddress(String domain) async {
    try {
      final ethAddress = await _getAddress(domain, 'ethereum');
      return ethAddress;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> getTezosAddress(String domain) async {
    try {
      final tezosAddress = await _getAddress(domain, 'tezos');
      return tezosAddress;
    } catch (e) {
      unawaited(
        Sentry.captureException(
          'Error getting tezos address for $domain: $e',
        ),
      );
      return null;
    }
  }

  @override
  Future<String?> getAddress(String domain) async {
    final ethAddress = await getEthAddress(domain);
    if (ethAddress != null) {
      return ethAddress;
    }
    final tezosAddress = await getTezosAddress(domain);
    return tezosAddress;
  }
}

class GraphClient {
  GraphClient(this._url);

  final String _url;

  GraphQLClient get client {
    final httpLink = HttpLink(
      _url,
      defaultHeaders: {
        'X-API-KEY': Environment.domainResolverApiKey,
      },
    );
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
      log.info('Querying: $doc');
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
      log.info('Error querying: $e');
      unawaited(Sentry.captureException('[DomainService] Error querying: $e'));
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

  Future<String> _getToken() async => '';
}
