import 'package:graphql_flutter/graphql_flutter.dart';

abstract class DomainService {
  Future<String?> getAddress(String domain);

  Future<String?> getEthAddress(String domain);

  Future<String?> getTezosAddress(String domain);
}

class DomainServiceImpl implements DomainService {
  static const String _tnsDomain = 'https://api.tezos.domains/graphql';
  static const String _ensDomain =
      'https://api.thegraph.com/subgraphs/name/ensdomains/ens';
  static const String _tnsQuery = '''
    { domains(where: { name: { in: ["<var>"] } }) { items { address name} } }
  ''';

  static const String _ensQuery = '''
    { domains(where: {name: "<var>"}) { name resolvedAddress { id } } }
  ''';

  static GraphClient get _tnsClient => GraphClient(_tnsDomain);

  static GraphClient get _ensClient => GraphClient(_ensDomain);

  @override
  Future<String?> getEthAddress(String domain) async {
    try {
      final result = await _ensClient.query(
        doc: _ensQuery.replaceFirst('<var>', domain),
        subKey: 'domains',
      );
      if (result == null || result.isEmpty) {
        return null;
      }
      return result.first['resolvedAddress']['id'];
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> getTezosAddress(String domain) async {
    try {
      final result = await _tnsClient.query(
        doc: _tnsQuery.replaceFirst('<var>', domain),
        subKey: 'domains',
      );
      if (result == null) {
        return null;
      }
      final items = result['items'];
      if (items == null || items.isEmpty) {
        return null;
      }
      return items.first['address'];
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> getAddress(String domain) async {
    final ethAddress = await getEthAddress(domain);
    if (ethAddress != null) {
      return ethAddress;
    }
    return await getTezosAddress(domain);
  }
}

class GraphClient {
  GraphClient(this._url);

  final String _url;

  GraphQLClient get client {
    final httpLink = HttpLink(_url);
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
