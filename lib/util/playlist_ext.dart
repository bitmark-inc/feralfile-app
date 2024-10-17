import 'package:autonomy_flutter/model/play_list_model.dart';

extension PlaylistExt on PlayListModel {
  String? get displayKey {
    final listTokenIds = tokenIDs;
    return listTokenIds.displayKey;
  }

  bool get isEditable => source == PlayListSource.manual;

  bool get requiredPremiumToDisplay => source != PlayListSource.activation;
}

extension ListTokenIdsExt on List<String> {
  String? get displayKey {
    if (isEmpty) {
      return null;
    }
    final hashCodes = map((e) => e.hashCode).toList();
    final hashCode = hashCodes.reduce((value, element) => value ^ element);
    return hashCode.toString();
  }
}
