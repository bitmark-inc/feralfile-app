import 'package:autonomy_flutter/util/xtz_utils.dart';

extension IntExtension on int {
  String get toXTZStringValue => '${XtzAmountFormatter().format(this)} XTZ';
}

extension MapExtention on Map {
  Map<K, T> typeCast<K, T>() {
    if (this is Map<K, T>) {
      return this as Map<K, T>;
    } else {
      // Attempt to cast the map elements
      return map<K, T>(
        (key, value) => MapEntry(key as K, value as T),
      );
    }
  }
}
