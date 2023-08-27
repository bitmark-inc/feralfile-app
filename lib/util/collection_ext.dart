import 'package:autonomy_flutter/model/play_list_model.dart';

extension ListCollectionExt on List<PlayListModel> {
  List<PlayListModel> filter(String? filter) {
    if (filter == null || filter.isEmpty) {
      return this;
    }
    return where((element) => element.name!.contains(filter)).toList();
  }
}
