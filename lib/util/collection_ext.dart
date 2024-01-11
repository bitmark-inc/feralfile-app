import 'package:autonomy_flutter/model/play_list_model.dart';

extension ListCollectionExt on List<PlayListModel> {
  List<PlayListModel> filter(String? filter) {
    if (filter == null || filter.isEmpty) {
      return this;
    }
    final lowerFilter = filter.toLowerCase();
    return where(
            (element) => element.getName().toLowerCase().contains(lowerFilter))
        .toList();
  }
}
