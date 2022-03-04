import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/entity/identity.dart';
import 'package:autonomy_flutter/gateway/indexer_api.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'identity_state.dart';

class IdentityBloc extends Bloc<IdentityEvent, IdentityState> {
  AppDatabase _appDB;
  IndexerApi _indexerApi;

  static const localIdentityCacheDuration = Duration(days: 7);

  IdentityBloc(this._appDB, this._indexerApi) : super(IdentityState({})) {
    on<GetIdentityEvent>((event, emit) async {
      try {
        Map<String, String> resultFromDB = {};
        List<String> unknownIdentities = [];

        // Try to get from the database first.
        await Future.forEach(event.addresses, (address) async {
          final identity =
              await _appDB.identityDao.findByAccountNumber(address as String);
          if (identity != null) {
            if (identity.queriedAt
                    .add(localIdentityCacheDuration)
                    .compareTo(DateTime.now()) ==
                -1) {
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
            final identity = await _indexerApi.getIdentity(address as String);
            resultFromAPI[address] = identity.name;
            _appDB.identityDao.insertIdentity(Identity(
                identity.accountNumber, identity.blockchain, identity.name));
          } catch (_) {
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
  }
}
