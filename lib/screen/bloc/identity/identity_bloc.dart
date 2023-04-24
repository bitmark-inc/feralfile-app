//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/entity/identity.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:nft_collection/graphql/model/identity.dart';
import 'package:nft_collection/services/indexer_service.dart';

part 'identity_state.dart';

class IdentityBloc extends AuBloc<IdentityEvent, IdentityState> {
  final AppDatabase _appDB;
  final IndexerService _indexerService;

  static const localIdentityCacheDuration = Duration(days: 1);

  IdentityBloc(this._appDB, this._indexerService) : super(IdentityState({})) {
    on<GetIdentityEvent>((event, emit) async {
      try {
        Map<String, String> resultFromDB = {};
        List<String> unknownIdentities = [];

        // Try to get from the database first.
        await Future.forEach<String>(event.addresses, (address) async {
          if (address.contains(' ') || address.length < 36) {
            return;
          }

          final identity =
              await _appDB.identityDao.findByAccountNumber(address);
          if (identity != null) {
            if (identity.queriedAt
                    .add(localIdentityCacheDuration)
                    .compareTo(DateTime.now()) >=
                0) {
              if (identity.name.isEmpty) {
                unknownIdentities.add(address);
                return;
              }
              // If the identity cache are still ok, add to the map
              resultFromDB[address] = identity.name;
            } else {
              // Remove those item from the database
              await _appDB.identityDao.deleteIdentity(identity);
              // Re-query from the API
              unknownIdentities.add(address);
            }
          } else {
            unknownIdentities.add(address);
          }
        });
        if (resultFromDB.isNotEmpty) {
          emit(IdentityState(resultFromDB));
        }

        // Stop if nothing obsolete
        if (unknownIdentities.isEmpty) {
          return;
        }
        Map<String, String> resultFromAPI = {};
        // Get from the API
        await Future.forEach(unknownIdentities, (address) async {
          try {
            final request = QueryIdentityRequest(account: address as String);
            final identity = await _indexerService.getIdentity(request);
            resultFromAPI[address] = identity.name;
            _appDB.identityDao.insertIdentity(Identity(
                identity.accountNumber, identity.blockchain, identity.name));
          } catch (_) {
            // Ignore bad API responses
            return;
          }
        });

        if (resultFromAPI.isNotEmpty) {
          Map<String, String> result = {}
            ..addAll(resultFromDB)
            ..addAll(resultFromAPI);
          emit(IdentityState(result));
        }
      } catch (error) {
        log.warning("Error during getting the identities: $error");
        emit(state);
      }
    });

    on<FetchIdentityEvent>((event, emit) async {
      // Get from the API
      await Future.forEach(event.addresses, (address) async {
        try {
          final request = QueryIdentityRequest(account: address as String);
          final identity = await _indexerService.getIdentity(request);
          _appDB.identityDao.insertIdentity(Identity(
              identity.accountNumber, identity.blockchain, identity.name));
        } catch (_) {
          // Ignore bad API responses
          return;
        }
      });
    });

    on<RemoveAllEvent>((event, emit) async {
      await _appDB.identityDao.removeAll();
    });
  }
}
