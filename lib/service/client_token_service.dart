import 'dart:async';

import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/pending_token_service.dart';
import 'package:nft_collection/widgets/nft_collection_bloc.dart';
import 'package:nft_collection/widgets/nft_collection_bloc_event.dart';

class ClientTokenService {
  ClientTokenService(
    this._addressService,
    this._pendingTokenService,
    this._nftBloc,
  );

  final AddressService _addressService;
  final PendingTokenService _pendingTokenService;
  final NftCollectionBloc _nftBloc;

  NftCollectionBloc get nftBloc => _nftBloc;

  List<String> getAddresses() {
    final addresses = _addressService.getAllAddresses();
    return addresses.map((e) => e.address).toList();
  }

  Future<void> refreshTokens({
    bool checkPendingToken = false,
    bool syncAddresses = false,
  }) async {
    if (syncAddresses && !_nftBloc.prefs.getDidSyncAddress()) {
      final addresses = getAddresses();
      final hiddenAddresses = _addressService.getAllAddresses(isHidden: true);

      await _nftBloc.addressService.addAddresses(addresses);
      await _nftBloc.addressService.setIsHiddenAddresses(
        hiddenAddresses.map((e) => e.address).toList(),
        true,
      );
      unawaited(_nftBloc.prefs.setDidSyncAddress(true));
    }

    _nftBloc.add(RefreshNftCollectionByOwners());

    if (checkPendingToken) {
      final activeAddresses = _addressService
          .getAllAddresses(isHidden: true)
          .map((e) => e.address)
          .toList();

      final pendingResults = await Future.wait(
        activeAddresses.where((address) => address.startsWith('tz')).map(
              (address) => _pendingTokenService.checkPendingTezosTokens(
                address,
                maxRetries: 1,
              ),
            ),
      );
      if (pendingResults.any((e) => e.isNotEmpty)) {
        _nftBloc.add(
          UpdateTokensEvent(
            tokens: pendingResults.expand((e) => e).toList(),
          ),
        );
      }
    }
  }
}
