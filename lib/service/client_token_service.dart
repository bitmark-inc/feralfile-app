import 'dart:async';

import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/pending_token_service.dart';
import 'package:nft_collection/widgets/nft_collection_bloc.dart';
import 'package:nft_collection/widgets/nft_collection_bloc_event.dart';

class ClientTokenService {
  final AccountService _accountService;
  final CloudManager _cloudObjects;
  final PendingTokenService _pendingTokenService;
  final NftCollectionBloc _nftBloc;

  ClientTokenService(this._accountService, this._cloudObjects,
      this._pendingTokenService, this._nftBloc);

  NftCollectionBloc get nftBloc => _nftBloc;

  Future<List<String>> getAddresses() async =>
      await _accountService.getAllAddresses();

  Future<List<String>> getManualTokenIds() async {
    final tokenIndexerIDs = _cloudObjects.connectionObject
        .getConnectionsByType(ConnectionType.manuallyIndexerTokenID.rawValue)
        .map((e) => e.key)
        .toList();
    return tokenIndexerIDs;
  }

  Future refreshTokens(
      {bool checkPendingToken = false, bool syncAddresses = false}) async {
    if (syncAddresses && !_nftBloc.prefs.getDidSyncAddress()) {
      final addresses = await _accountService.getAllAddresses();
      final hiddenAddresses = await _accountService.getHiddenAddressIndexes();

      await _nftBloc.addressService.addAddresses(addresses);
      await _nftBloc.addressService.setIsHiddenAddresses(
          hiddenAddresses.map((e) => e.address).toList(), true);
      unawaited(_nftBloc.prefs.setDidSyncAddress(true));
    }
    final indexerIds = await getManualTokenIds();

    _nftBloc.add(RefreshNftCollectionByOwners(
      debugTokens: indexerIds,
    ));

    if (checkPendingToken) {
      final activeAddresses = await _accountService.getShowedAddresses();
      final pendingResults = await Future.wait(activeAddresses
          .where((address) => address.startsWith('tz'))
          .map((address) => _pendingTokenService
              .checkPendingTezosTokens(address, maxRetries: 1)));
      if (pendingResults.any((e) => e.isNotEmpty)) {
        _nftBloc.add(UpdateTokensEvent(
            tokens: pendingResults.expand((e) => e).toList()));
      }
    }
  }
}
