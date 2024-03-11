abstract class ProjectsEvent {}

class GetProjectsEvent extends ProjectsEvent {}

class ProjectsState {
  final bool loading;

  final bool showYokoOno;

  ProjectsState({
    this.loading = true,
    this.showYokoOno = false,
  });

  ProjectsState copyWith({
    bool? loading,
    bool? showYokoOno,
  }) =>
      ProjectsState(
        loading: loading ?? this.loading,
        showYokoOno: showYokoOno ?? this.showYokoOno,
      );
}
