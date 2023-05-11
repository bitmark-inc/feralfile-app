import 'package:floor/floor.dart';

@entity
class CanvasDevice {
  @primaryKey
  final String id;
  final String ip;
  final int port;
  final String name;
  final String? lastScenePlayed;

  // constructor
  CanvasDevice({
    required this.id,
    required this.ip,
    required this.port,
    required this.name,
    this.lastScenePlayed,
  });


  //fromJson method
  factory CanvasDevice.fromJson(Map<String, dynamic> json) => CanvasDevice(
        id: json["id"] as String,
        ip: json["ip"] as String,
        port: json["port"] as int,
        name: json["name"] as String,
        lastScenePlayed: json["lastScenePlayed"] as String?,
      );

  // toJson
  Map<String, dynamic> toJson() => {
        "id": id,
        "ip": ip,
        "port": port,
        "name": name,
        "lastScenePlayed": lastScenePlayed,
      };
}

@entity
class Scene {
  @primaryKey
  final String id;
  final String deviceId;
  final String metadata;

  // constructor
  Scene({
    required this.id,
    required this.deviceId,
    required this.metadata,
  });

  // fromJson method
  factory Scene.fromJson(Map<String, dynamic> json) => Scene(
        id: json["id"] as String,
        deviceId: json["deviceId"] as String,
        metadata: json["metadata"] as String,
      );

  // toJson
  Map<String, dynamic> toJson() => {
        "id": id,
        "deviceId": deviceId,
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
