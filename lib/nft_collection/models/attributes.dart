import 'package:autonomy_flutter/screen/bloc/artist_artwork_display_settings/artist_artwork_display_setting_bloc.dart';

class Attributes {
  Attributes({
    this.configuration,
  });

  factory Attributes.fromJson(Map<String, dynamic> map) {
    return Attributes(
      configuration: map['configuration'] != null
          ? ArtistDisplaySetting.fromJson(
              Map<String, dynamic>.from(map['configuration'] as Map),
            )
          : null,
    );
  }

  ArtistDisplaySetting? configuration;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'configuration': configuration?.toJson(),
    };
  }
}
