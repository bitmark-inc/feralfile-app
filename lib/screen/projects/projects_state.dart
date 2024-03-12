import 'package:autonomy_flutter/model/tap_navigate.dart';

abstract class ProjectsEvent {}

class GetProjectsEvent extends ProjectsEvent {}

class ProjectsState {
  final bool loading;

  final List<TapNavigate> projects;

  ProjectsState({
    this.loading = true,
    this.projects = const [],
  });

  ProjectsState copyWith({
    bool? loading,
    List<TapNavigate>? projects,
  }) =>
      ProjectsState(
        loading: loading ?? this.loading,
        projects: projects ?? this.projects,
      );
}
