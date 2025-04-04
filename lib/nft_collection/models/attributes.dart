import 'package:autonomy_flutter/screen/bloc/artist_artwork_display_settings/artist_artwork_display_setting_bloc.dart';

class Attributes {
  Attributes({
    required this.artistDisplaySetting,
  });

  factory Attributes.fromJson(Map<String, dynamic> map) {
    return Attributes(
      artistDisplaySetting: map['configuration'] == null
          ? null
          : ArtistDisplaySetting.fromJson(
              map['configuration'] as Map<String, dynamic>,
            ),
    );
  }

  final ArtistDisplaySetting? artistDisplaySetting;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'configuration': artistDisplaySetting?.toJson(),
    };
  }
}
