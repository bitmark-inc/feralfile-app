.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/pending_token_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/foundation.dart';
import 'package:nft_collection/models/address_index.dart';
import 'package:nft_collection/widgets/nft_collection_bloc.dart';
import 'package:nft_collection/widgets/nft_collection_bloc_event.dart';

class ClientTokenService {
  final AccountService _accountService;
  final CloudDatabase _cloudDatabase;
  final PendingTokenService _pendingTokenService;
  final NftCollectionBloc nftBloc;

  ClientTokenService(this._accountService, this._cloudDatabase,
      this._pendingTokenService, this.nftBloc);

  Future<List<AddressIndex>> getAddressIndexes() async {
    return await _accountService.getAllAddressIndexes();
  }

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

  Future refreshTokens({checkPendingToken = false}) async {
    final value = await Future.wait([
      getAddressIndexes(),
      getManualTokenIds(),
      _accountService.getHiddenAddressIndexes(),
    ]);
    final addresses = value[0] as List<AddressIndex>;
    final indexerIds = value[1] as List<String>;
    final hiddenAddresses = value[2] as List<AddressIndex>;

    final activeAddresses = addresses
        .where((element) => !hiddenAddresses.contains(element))
        .map((e) => e.address)
        .toList();
    final isRefresh =
        !listEquals(activeAddresses, NftCollectionBloc.activeAddress);
    log.info("[HomePage] activeAddresses: $activeAddresses");
    log.info(
        "[HomePage] NftCollectionBloc.activeAddress: ${NftCollectionBloc.activeAddress}");
    if (isRefresh) {
      final listDifferents = activeAddresses
          .where(
              (element) => !NftCollectionBloc.activeAddress.contains(element))
          .toList();
      if (listDifferents.isNotEmpty) {
        nftBloc.add(GetTokensBeforeByOwnerEvent(
          pageKey: nftBloc.state.nextKey,
          owners: listDifferents,
        ));
      }
    }

    nftBloc.add(RefreshNftCollectionByOwners(
      hiddenAddresses: hiddenAddresses,
      addresses: addresses,
      debugTokens: indexerIds,
      isRefresh: isRefresh,
    ));

    if (checkPendingToken) {
      final pendingResults = await Future.wait(activeAddresses
          .where((address) => address.startsWith("tz"))
          .map((address) => _pendingTokenService
              .checkPendingTezosTokens(address, maxRetries: 1)));
      if (pendingResults.any((e) => e.isNotEmpty)) {
        nftBloc.add(UpdateTokensEvent(
            tokens: pendingResults.expand((e) => e).toList()));
      }
    }
  }
}
