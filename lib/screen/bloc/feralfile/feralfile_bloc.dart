//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:collection/collection.dart';
import 'package:libauk_dart/libauk_dart.dart';

part 'feralfile_state.dart';

class FeralfileBloc extends AuBloc<FeralFileEvent, FeralFileState> {
  final FeralFileService _feralFileService;
  final CloudDatabase _cloudDB;

  // TODO: Improve using cache?
  Future<Persona?> getPersonaFromETHAddress(String address) async {
    final personas = await _cloudDB.personaDao.getPersonas();
    for (var persona in personas) {
      final ethAddress = await persona.wallet().getETHEip55Address();
      if (ethAddress == address) {
        return persona;
      }
    }
    return null;
  }

  static FeralfileBloc create() {
    return FeralfileBloc(injector(), injector());
  }

  FeralfileBloc(this._feralFileService, this._cloudDB)
      : super(FeralFileState()) {
    on<GetFFAccountInfoEvent>((event, emit) async {
      try {
        final oldConnection = event.connection;
        emit(state.copyWith(connection: oldConnection));

        switch (oldConnection.connectionType) {
          case 'feralFileWeb3':
            final personaAddress =
                oldConnection.ffWeb3Connection?.personaAddress;
            if (personaAddress == null) return;
            final persona = await getPersonaFromETHAddress(personaAddress);
            if (persona == null) return;

            final ffAccount =
                await _feralFileService.getWeb3Account(persona.wallet());
            final connection = oldConnection.copyFFWith(ffAccount);

            await _cloudDB.connectionDao.updateConnection(connection);
            emit(state.copyWith(connection: connection));

            break;

          case 'feralFileToken':
            final ffToken = oldConnection.key;
            final ffAccount = await _feralFileService.getAccount(ffToken);
            final connection = oldConnection.copyFFWith(ffAccount);

            await _cloudDB.connectionDao.updateConnection(connection);
            emit(state.copyWith(connection: connection));
            break;
        }
      } catch (error) {
        emit(state.copyWith(refreshState: ActionState.error));
      }
    });

    on<LinkFFWeb3AccountEvent>((event, emit) async {
      final retryLimit = event.shouldRetry ? 11 : 0; // doing in 1 minutes
      var retries = 0;

      while (true) {
        try {
          final personaAddress = await event.wallet.getETHEip55Address();
          final ffAccount =
              await _feralFileService.getWeb3Account(event.wallet);

          final alreadyLinkedAccount = await getExistingAccount(ffAccount);
          if (alreadyLinkedAccount != null) {
            emit(state.setEvent(AlreadyLinkedError(alreadyLinkedAccount)));
            return;
          }

          final connection = Connection.fromFFWeb3(
              event.topic, event.source, personaAddress, ffAccount);
          _cloudDB.connectionDao.insertConnection(connection);
          emit(state.setEvent(LinkAccountSuccess(connection)));
          return;
        } catch (error) {
          // loop with delay because FeralFile may take time to execute 2FA
          if (retries < retryLimit) {
            retries++;
            await Future.delayed(const Duration(seconds: 5));
          } else {
            final code = decodeErrorResponse(error);
            if (code == null) rethrow;

            final apiError = getAPIErrorCode(code);
            if (apiError == APIErrorCode.ffNotConnected ||
                apiError == APIErrorCode.notLoggedIn) {
              emit(state.setEvent(FFNotConnected()));
              return;
            }
            rethrow;
          }
        }
      }
    });

    on<UnlinkFFWeb3AccountEvent>((event, emit) async {
      final connections = await _cloudDB.connectionDao.getConnections();
      final ffConnection = connections.firstWhereOrNull((conn) {
        return conn.ffWeb3Connection?.source == event.source &&
            conn.ffWeb3Connection?.personaAddress == event.address;
      });
      if (ffConnection != null) {
        await _cloudDB.connectionDao.deleteConnection(ffConnection);
      }
      emit(state.copyWith(event: FFUnlinked()));
    });
  }

  Future<Connection?> getExistingAccount(FFAccount ffAccount) async {
    final existingConnections = await _cloudDB.connectionDao
        .getConnectionsByAccountNumber(ffAccount.id);

    if (existingConnections.isEmpty) return null;

    return existingConnections.first;
  }
}
