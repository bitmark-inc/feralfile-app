import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'feralfile_state.dart';

class FeralfileBloc extends Bloc<FeralFileEvent, FeralFileState> {
  ConfigurationService _configurationService;
  FeralFileService _feralFileService;
  CloudDatabase _cloudDB;

  FeralfileBloc(
      this._configurationService, this._feralFileService, this._cloudDB)
      : super(FeralFileState()) {
    on<GetFFAccountInfoEvent>((event, emit) async {
      try {
        final oldConnection = event.connection;
        emit(state.copyWith(connection: oldConnection));
        final ffToken = oldConnection.key;
        final ffAccount = await _feralFileService.getAccount(ffToken);
        final connection = oldConnection.copyFFWith(ffAccount);

        _cloudDB.connectionDao.updateConnection(connection);
        emit(state.copyWith(connection: connection));
      } catch (error) {
        emit(state.copyWith(refreshState: ActionState.error));
      }
    });

    on<LinkFFAccountInfoEvent>((event, emit) async {
      // try {
      final network = _configurationService.getNetwork();
      final source = network == Network.MAINNET
          ? "https://feralfile.com"
          : "https://feralfile1.dev.bitmark.com";

      final ffToken = event.token;
      final ffAccount = await _feralFileService.getAccount(ffToken);
      final connection = Connection.fromFFToken(ffToken, source, ffAccount);

      _cloudDB.connectionDao.insertConnection(connection);

      emit(FeralFileState(linkState: ActionState.done));
      // } catch (error) {
      //   emit(FeralFileState(linkState: ActionState.error));
      //   rethrow
      // }
    });
  }
}
