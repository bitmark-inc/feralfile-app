import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Event
abstract class FFDirectoriesEvent {}

class GetDirectoriesEvent extends FFDirectoriesEvent {}

// State
class FFDirectoriesState {
  FFDirectoriesState({
    this.directories = const [],
    this.loading = false,
    this.error,
  });

  final List<FFDirectory> directories;
  final bool loading;
  final Object? error;

  FFDirectoriesState copyWith({
    List<FFDirectory>? directories,
    bool? loading,
    Object? error,
  }) {
    return FFDirectoriesState(
      directories: directories ?? this.directories,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}

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
    await Future.delayed(const Duration(seconds: 1));
    return <FFDirectory>[
      FFDirectory('Art Blocks'),
      FFDirectory('Aorist'),
      FFDirectory('Feral File'),
      FFDirectory('MoMA'),
    ];
  }
}
