import 'package:floor/floor.dart';

@entity
class CanvasDevice {
  @primaryKey
  final String id;
  final String ip;
  final int port;
  final String name;
  bool isConnecting;
  String? playingSceneId;

  // constructor
  CanvasDevice({
    required this.id,
    required this.ip,
    required this.port,
    required this.name,
    this.isConnecting = false,
    this.playingSceneId,
  });

  //fromJson method
  factory CanvasDevice.fromJson(Map<String, dynamic> json) => CanvasDevice(
        id: json["id"] as String,
        ip: json["ip"] as String,
        port: json["port"] as int,
        name: json["name"] as String,
        isConnecting: json["isConnecting"] as bool,
        playingSceneId: json["playingSceneId"] as String?,
      );

  // toJson
  Map<String, dynamic> toJson() => {
        "id": id,
        "ip": ip,
        "port": port,
        "name": name,
        "isConnecting": isConnecting,
        "playingSceneId": playingSceneId,
      };

  // copyWith
  CanvasDevice copyWith({
    String? id,
    String? ip,
    int? port,
    String? name,
    bool? isConnecting,
    String? playingSceneId,
  }) {
    return CanvasDevice(
      id: id ?? this.id,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      name: name ?? this.name,
      isConnecting: isConnecting ?? this.isConnecting,
      playingSceneId: playingSceneId ?? this.playingSceneId,
    );
  }
}

@entity
class Scene {
  @primaryKey
  final String id;
  final String deviceId;
  final bool isPlaying;
  final String metadata;

  // constructor
  Scene({
    required this.id,
    required this.deviceId,
    required this.metadata,
    this.isPlaying = false,
  });

  // fromJson method
  factory Scene.fromJson(Map<String, dynamic> json) => Scene(
        id: json["id"] as String,
        deviceId: json["deviceId"] as String,
        isPlaying: json["isPlaying"] as bool,
        metadata: json["metadata"] as String,
      );

  // toJson
  Map<String, dynamic> toJson() => {
        "id": id,
        "deviceId": deviceId,
        "isPlaying": isPlaying,
        "metadata": metadata,
      };
}

class SceneMetadata {
  final String sceneName;
  final List<String> tokenId;

  // constructor
  SceneMetadata({
    required this.sceneName,
    required this.tokenId,
  });

  // fromJson method
  factory SceneMetadata.fromJson(Map<String, dynamic> json) => SceneMetadata(
        sceneName: json["sceneName"] as String,
        tokenId: json["tokenId"] as List<String>,
      );

  // toJson
  Map<String, dynamic> toJson() => {
        "sceneName": sceneName,
        "tokenId": tokenId,
      };
}
