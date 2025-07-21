import 'package:autonomy_flutter/nft_collection/database/dao/token_dao.dart';
import 'package:autonomy_flutter/nft_collection/models/models.dart';

class MockTokenDao extends TokenDao {
  @override
  Future<void> insertTokens(List<Token> tokens) async {}

  @override
  Future<void> deleteTokens(List<String> tokenIds) async {}

  @override
  Future<List<Token>> findAllTokens() async {
    return [];
  }

  @override
  Future<void> deleteTokenByID(String tokenID) async {}

  @override
  Future<void> deleteTokensByOwners(List<String> owners) async {}

  @override
  Future<List<Token>> findAllPendingTokens() async {
    return [];
  }

  @override
  Future<List<String>> findAllTokenIDs() async {
    return [];
  }

  @override
  Future<List<Token>> findAllTokensByOwners(List<String> owners) async {
    return [];
  }

  @override
  Future<List<Token>> findAllTokensByTokenIDs(List<String> tokenIDs) async {
    return [];
  }

  @override
  Future<void> insertToken(Token token) async {}

  @override
  Future<void> removeAll() async {}

  @override
  Future<List<String>> findTokenIDsByOwners(List<String> owners) async {
    return [];
  }

  @override
  Future<List<String>> findTokenIDsOwnersOwn(List<String> owners) async {
    return [];
  }

  @override
  Future<List<Token>> findTokensByID(String tokenID) async {
    return [];
  }

  @override
  Future<void> insertTokensAbort(List<Token> tokens) async {}
}
