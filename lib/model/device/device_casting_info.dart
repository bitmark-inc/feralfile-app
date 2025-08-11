import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/device/device_display_setting.dart';

class DeviceCastingInfo {
  DeviceCastingInfo({
    required this.artworks,
    this.index,
    bool? isPaused,
    this.connectedDevice,
    this.exhibitionId,
    this.catalogId,
    this.catalog,
    this.displayKey,
    this.deviceSettings,
  }) : isPaused = isPaused ?? false;

  factory DeviceCastingInfo.fromJson(Map<String, dynamic> json) =>
      DeviceCastingInfo(
        artworks: json['artworks'] == null
            ? []
            : List<PlayArtworkV2>.from(
                (json['artworks'] as List).map(
                  (x) => PlayArtworkV2.fromJson(x as Map<String, dynamic>),
                ),
              ),
        index: json['index'] as int?,
        isPaused: json['isPaused'] as bool?,
        connectedDevice: json['connectedDevice'] != null
            ? DeviceInfoV2.fromJson(
                json['connectedDevice'] as Map<String, dynamic>,
              )
            : null,
        exhibitionId: json['exhibitionId'] as String?,
        catalogId: json['catalogId'] as String?,
        catalog: json['catalog'] == null
            ? null
            : ExhibitionCatalog.values[json['catalog'] as int],
        displayKey: json['displayKey'] as String?,
        deviceSettings: json['deviceSettings'] != null
            ? DeviceDisplaySetting.fromJson(
                json['deviceSettings'] as Map<String, dynamic>,
              )
            : null,
      );

  int? get currentArtworkIndex {
    if (artworks.isEmpty) {
      return null;
    }
    return index;
  }

  List<PlayArtworkV2> artworks;
  int? index;
  bool isPaused;
  DeviceInfoV2? connectedDevice;
  String? exhibitionId;
  String? catalogId;
  ExhibitionCatalog? catalog;
  String? displayKey;
  DeviceDisplaySetting? deviceSettings;

  DeviceCastingInfo copyWith({
    List<PlayArtworkV2>? artworks,
    int? index,
    bool? isPaused,
    DeviceInfoV2? connectedDevice,
    String? exhibitionId,
    String? catalogId,
    ExhibitionCatalog? catalog,
    String? displayKey,
    DeviceDisplaySetting? deviceSettings,
  }) {
    return DeviceCastingInfo(
      artworks: artworks ?? this.artworks,
      index: index ?? this.index,
      isPaused: isPaused ?? this.isPaused,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      exhibitionId: exhibitionId ?? this.exhibitionId,
      catalogId: catalogId ?? this.catalogId,
      catalog: catalog ?? this.catalog,
      displayKey: displayKey ?? this.displayKey,
      deviceSettings: deviceSettings ?? this.deviceSettings,
    );
  }
}
