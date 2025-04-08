import 'package:autonomy_flutter/screen/bloc/artist_artwork_display_settings/artist_artwork_display_setting_bloc.dart';

class QueryListTokenConfigurationsResponse {
  QueryListTokenConfigurationsResponse({
    required this.tokenConfigurations,
  });

  factory QueryListTokenConfigurationsResponse.fromJson(
      Map<String, dynamic> map) {
    return QueryListTokenConfigurationsResponse(
      tokenConfigurations: map['tokens'] != null
          ? List<ArtistDisplaySetting?>.from(
              (map['tokens'] as List<dynamic>).map<ArtistDisplaySetting?>(
                (token) => token['asset']['attributes'] != null &&
                        token['asset']['attributes']['configuration'] != null
                    ? ArtistDisplaySetting.fromJson(
                        token['asset']['attributes']['configuration']
                            as Map<String, dynamic>,
                      )
                    : null,
              ),
            )
          : [],
    );
  }

  List<ArtistDisplaySetting?> tokenConfigurations;
}
