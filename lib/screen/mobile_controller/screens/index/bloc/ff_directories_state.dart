part of 'ff_directories_bloc.dart';

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
