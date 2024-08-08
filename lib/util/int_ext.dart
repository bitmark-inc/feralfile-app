import 'package:autonomy_flutter/util/xtz_utils.dart';

extension IntExtension on int {
  String get toZTXStringValue => '${XtzAmountFormatter().format(this)} XTZ';
}
