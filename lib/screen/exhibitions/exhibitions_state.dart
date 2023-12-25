import 'package:autonomy_flutter/model/ff_exhibition.dart';

class ExhibitionsEvent {}

class GetAllExhibitionsEvent extends ExhibitionsEvent {}

class GetOpeningExhibitionsEvent extends ExhibitionsEvent {}

class ExhibitionsState {
  ExhibitionsState({
    this.exhibitions,
  });

  final List<Exhibition>? exhibitions;

  ExhibitionsState copyWith({
    List<Exhibition>? exhibitions,
  }) =>
      ExhibitionsState(
        exhibitions: exhibitions ?? this.exhibitions,
      );
}
