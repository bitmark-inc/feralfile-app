import 'package:autonomy_flutter/model/ff_user.dart';
import 'package:autonomy_flutter/util/alias_helper.dart';

extension FeralFileArtistExt on FFArtist {
  String get displayAlias =>
      AliasHelper.transform(alias, isArtistOrCurator: true);
  String get alias => alumniAccount?.alias ?? '';
}

extension FeralFileCuratorExt on FFCurator {
  String get displayAlias =>
      AliasHelper.transform(alias, isArtistOrCurator: true);

  String get alias => alumniAccount?.alias ?? '';
}
