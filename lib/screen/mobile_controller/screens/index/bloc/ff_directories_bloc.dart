import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/directory.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'ff_directories_event.dart';
part 'ff_directories_state.dart';

class FFDirectoriesBloc extends AuBloc<FFDirectoriesEvent, FFDirectoriesState> {
  FFDirectoriesBloc() : super(FFDirectoriesState()) {
    on<GetDirectoriesEvent>(_onGetDirectories);
  }

  Future<void> _onGetDirectories(
      GetDirectoriesEvent event, Emitter<FFDirectoriesState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final directories = await getFakeDirectories();
      emit(state.copyWith(directories: directories, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e));
    }
  }

  Future<List<FFDirectory>> getFakeDirectories() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return <FFDirectory>[
      FFDirectory('Art Blocks'),
      FFDirectory('Aorist'),
      FFDirectory('Feral File'),
      FFDirectory('MoMA'),
    ];
  }
}
