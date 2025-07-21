part of 'works_bloc.dart';

abstract class WorksEvent {
  const WorksEvent();
}

class LoadWorksEvent extends WorksEvent {
  const LoadWorksEvent();
}

class LoadMoreWorksEvent extends WorksEvent {
  const LoadMoreWorksEvent();
}

class RefreshWorksEvent extends WorksEvent {
  const RefreshWorksEvent();
}
