import 'package:hive_flutter/hive_flutter.dart';

class DisplayDevice {
  final String id;
  final String topicID;
  final String locationID;
  final String name;
  final String? alias;

  DisplayDevice({
    required this.id,
    required this.topicID,
    required this.locationID,
    required this.name,
    this.alias,
  });

  factory DisplayDevice.fromJson(Map<String, dynamic> json) => DisplayDevice(
        id: json['id'] as String,
        topicID: json['topicID'] as String,
        locationID: json['locationID'] as String,
        name: json['name'] as String,
        alias: json['alias'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'topicID': topicID,
        'locationID': locationID,
        'name': name,
        'alias': alias,
      };

  DisplayDevice copyWith({
    String? id,
    String? topicID,
    String? locationID,
    String? name,
    String? alias,
  }) =>
      DisplayDevice(
        id: id ?? this.id,
        topicID: topicID ?? this.topicID,
        locationID: locationID ?? this.locationID,
        name: name ?? this.name,
        alias: alias ?? this.alias,
      );
}

class DisplayDeviceAdapter extends TypeAdapter<DisplayDevice> {
  @override
  final int typeId = 0;

  @override
  DisplayDevice read(BinaryReader reader) => DisplayDevice(
        id: reader.readString(),
        topicID: reader.readString(),
        locationID: reader.readString(),
        name: reader.readString(),
        alias: reader.readString(),
      );

  @override
  void write(BinaryWriter writer, DisplayDevice obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.topicID)
      ..writeString(obj.locationID)
      ..writeString(obj.name)
      ..writeString(obj.alias ?? '');
  }
}
