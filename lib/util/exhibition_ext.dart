import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';

extension ExhibitionExt on Exhibition {
  String get coverUrl => '${Environment.feralFileAssetURL}/$coverURI';

  bool get isGroupExhibition => type == 'group';

  //TODO: implement this
  bool get isFreeToStream => true;

  //TODO: implement this
  bool get isOnGoing => true;
}
