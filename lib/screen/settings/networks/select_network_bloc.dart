import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectNetworkBloc extends Bloc<SelectNetworkEvent, Network> {
  ConfigurationService _configurationService;

  SelectNetworkBloc(this._configurationService)
      : super(_configurationService.getNetwork()) {
    on<SelectNetworkEvent>((event, emit) async {
      await _configurationService.setNetwork(event.network);
      emit(event.network);
    });
  }
}

class SelectNetworkEvent {
  final Network network;

  SelectNetworkEvent(this.network);
}
