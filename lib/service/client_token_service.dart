import 'dart:async';

import 'package:autonomy_flutter/nft_collection/widgets/nft_collection_bloc.dart';
import 'package:autonomy_flutter/nft_collection/widgets/nft_collection_bloc_event.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/pending_token_service.dart';

abstract class ClientTokenService {
  NftCollectionBloc get nftBloc;

  List<String> getAddresses();

  Future<void> refreshTokens({
    bool checkPendingToken = false,
    bool syncAddresses = false,
  });
}

class ClientTokenServiceImpl implements ClientTokenService {
  ClientTokenServiceImpl(
    this._addressService,
    this._nftBloc,
  );

  final AddressService _addressService;
  final NftCollectionBloc _nftBloc;

  @override
  NftCollectionBloc get nftBloc => _nftBloc;

  @override
  List<String> getAddresses() {
    final addresses = _addressService.getAllWalletAddresses();
    return addresses.map((e) => e.address).toList();
  }

  @override
  Future<void> refreshTokens({
    bool checkPendingToken = false,
    bool syncAddresses = false,
  }) async {
    if (syncAddresses && !_nftBloc.prefs.getDidSyncAddress()) {
      final addresses = getAddresses();
      final hiddenAddresses =
          _addressService.getAllWalletAddresses(isHidden: true);

      await _nftBloc.addressService.addAddresses(addresses);
      await _nftBloc.addressService.setIsHiddenAddresses(
        hiddenAddresses.map((e) => e.address).toList(),
        true,
      );
      unawaited(_nftBloc.prefs.setDidSyncAddress(true));
    }

    _nftBloc.add(RefreshNftCollectionByOwners());
  }
}
