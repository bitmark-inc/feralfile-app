import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/nft_collection/widgets/nft_collection_bloc.dart';
import 'package:autonomy_flutter/service/client_token_service.dart';

class MockClientTokenService implements ClientTokenService {
  @override
  List<String> getAddresses() {
    // Mock implementation, returning an empty list
    return [];
  }

  @override
  NftCollectionBloc get nftBloc => injector<NftCollectionBloc>();

  @override
  Future<void> refreshTokens(
      {bool checkPendingToken = false, bool syncAddresses = false}) {
    // Mock implementation, does nothing
    return Future.value();
  }
}
