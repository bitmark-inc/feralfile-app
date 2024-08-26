import 'package:autonomy_flutter/model/project.dart';

abstract class ProjectsEvent {}

class GetProjectsEvent extends ProjectsEvent {}

class ProjectsState {
  final bool loading;
  final List<ProjectInfo> projects;

  ProjectsState({
    this.loading = true,
    this.projects = const [],
  });

  ProjectsState copyWith({
    bool? loading,
    List<ProjectInfo>? projects,
  }) =>
      ProjectsState(
        loading: loading ?? this.loading,
        projects: projects ?? this.projects,
      );
}
