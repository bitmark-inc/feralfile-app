import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:libauk_dart/libauk_dart.dart';

part 'feralfile_state.dart';

class FeralfileBloc extends Bloc<FeralFileEvent, FeralFileState> {
  ConfigurationService _configurationService;
  FeralFileService _feralFileService;
  CloudDatabase _cloudDB;

  // TODO: Improve using cache?
  Future<Persona?> getPersonaFromETHAddress(String address) async {
    final personas = await _cloudDB.personaDao.getPersonas();
    for (var persona in personas) {
      final ethAddress = await persona.wallet().getETHAddress();
      if (ethAddress == address) {
        return persona;
      }
    }
    return null;
  }

  FeralfileBloc(
      this._configurationService, this._feralFileService, this._cloudDB)
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

            _cloudDB.connectionDao.updateConnection(connection);
            emit(state.copyWith(connection: connection));

            break;

          case 'feralFileToken':
            final ffToken = oldConnection.key;
            final ffAccount = await _feralFileService.getAccount(ffToken);
            final connection = oldConnection.copyFFWith(ffAccount);

            _cloudDB.connectionDao.updateConnection(connection);
            emit(state.copyWith(connection: connection));
            break;
        }
      } catch (error) {
        emit(state.copyWith(refreshState: ActionState.error));
      }
    });

    on<LinkFFWeb3AccountEvent>((event, emit) async {
      try {
        final personaAddress = await event.wallet.getETHAddress();
        final ffAccount = await _feralFileService.getWeb3Account(event.wallet);

        final alreadyLinkedAccount = await getExistingAccount(ffAccount);
        if (alreadyLinkedAccount != null) {
          emit(state.setEvent(AlreadyLinkedError(alreadyLinkedAccount)));
          return;
        }

        final connection = Connection.fromFFWeb3(
            event.topic, event.source, personaAddress, ffAccount);
        _cloudDB.connectionDao.insertConnection(connection);
        emit(state.setEvent(LinkAccountSuccess(connection)));
      } catch (error) {
        final code = decodeErrorResponse(error);
        if (code == null) rethrow;

        final apiError = getAPIErrorCode(code);
        if (apiError == APIErrorCode.ffNotConnected) {
          emit(state.setEvent(FFNotConnected()));
          return;
        }

        rethrow;
      }
    });

    on<LinkFFAccountInfoEvent>((event, emit) async {
      try {
        final network = _configurationService.getNetwork();
        final source = network == Network.MAINNET
            ? "https://feralfile.com"
            : "https://feralfile1.dev.bitmark.com";

        final ffToken = event.token;
        final ffAccount = await _feralFileService.getAccount(ffToken);

        final alreadyLinkedAccount = await getExistingAccount(ffAccount);
        if (alreadyLinkedAccount != null) {
          emit(state.setEvent(AlreadyLinkedError(alreadyLinkedAccount)));
          return;
        }

        final connection = Connection.fromFFToken(ffToken, source, ffAccount);

        _cloudDB.connectionDao.insertConnection(connection);
        emit(state.setEvent(LinkAccountSuccess(connection)));
      } on DioError catch (error) {
        final code = decodeErrorResponse(error);
        if (code == null) rethrow;

        final apiError = getAPIErrorCode(code);
        if (apiError == APIErrorCode.notLoggedIn) {
          emit(state.setEvent(NotFFLoggedIn()));
          return;
        }
        rethrow;
      }
    });
  }

  Future<Connection?> getExistingAccount(FFAccount ffAccount) async {
    final existingConnections = await _cloudDB.connectionDao
        .getConnectionsByAccountNumber(ffAccount.accountNumber);

    if (existingConnections.isEmpty) return null;

    return existingConnections.first;
  }
}
