import 'package:autonomy_flutter/model/play_list_model.dart';

extension PlaylistExt on PlayListModel {
  String? get displayKey {
    final listTokenIds = tokenIDs ?? [];
    if (listTokenIds.isEmpty) {
      return null;
    }
    final hashCodes = listTokenIds.map((e) => e.hashCode).toList();
    final hashCode = hashCodes.reduce((value, element) => value ^ element);
    return hashCode.toString();
  }
}
