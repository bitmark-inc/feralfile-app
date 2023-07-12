import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/pending_token_service.dart';
import 'package:nft_collection/widgets/nft_collection_bloc.dart';
import 'package:nft_collection/widgets/nft_collection_bloc_event.dart';

class ClientTokenService {
  final AccountService _accountService;
  final CloudDatabase _cloudDatabase;
  final PendingTokenService _pendingTokenService;
  final NftCollectionBloc _nftBloc;

  ClientTokenService(this._accountService, this._cloudDatabase,
      this._pendingTokenService, this._nftBloc);

  NftCollectionBloc get nftBloc => _nftBloc;

  Future<List<String>> getAddresses() async {
    return await _accountService.getAllAddresses();
  }

  Future<List<String>> getManualTokenIds() async {
    final tokenIndexerIDs = (await _cloudDatabase.connectionDao
            .getConnectionsByType(
                ConnectionType.manuallyIndexerTokenID.rawValue))
        .map((e) => e.key)
        .toList();
    return tokenIndexerIDs;
  }

  Future refreshTokens(
      {checkPendingToken = false, bool syncAddresses = false}) async {
    if (syncAddresses && !_nftBloc.prefs.getDidSyncAddress()) {
      final addresses = await _accountService.getAllAddresses();
      final hiddenAddresses = await _accountService.getHiddenAddressIndexes();
      _nftBloc.add(AddAddressesEvent(
          addresses: addresses,
          hiddenAddresses: hiddenAddresses.map((e) => e.address).toList()));
      _nftBloc.prefs.setDidSyncAddress(true);
    }
    final indexerIds = await getManualTokenIds();

    _nftBloc.add(RefreshNftCollectionByOwners(
      debugTokens: indexerIds,
    ));

    if (checkPendingToken) {
      final activeAddresses = await _accountService.getShowedAddresses();
      final pendingResults = await Future.wait(activeAddresses
          .where((address) => address.startsWith("tz"))
          .map((address) => _pendingTokenService
              .checkPendingTezosTokens(address, maxRetries: 1)));
      if (pendingResults.any((e) => e.isNotEmpty)) {
        _nftBloc.add(UpdateTokensEvent(
            tokens: pendingResults.expand((e) => e).toList()));
      }
    }
  }
}
