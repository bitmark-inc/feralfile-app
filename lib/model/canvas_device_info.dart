class CanvasDevice {
  final String deviceId; //hardware id
  final String locationId; // location id
  final String topicId; // topic id
  final String name; // device name

  // constructor
  CanvasDevice({
    required this.deviceId,
    required this.locationId,
    required this.topicId,
    required this.name,
  });

  //fromJson method
  factory CanvasDevice.fromJson(Map<String, dynamic> json) => CanvasDevice(
        deviceId: json["deviceId"] as String,
        locationId: json["locationId"] as String,
        topicId: json["topicId"] as String,
        name: json["name"] as String,
      );

  // toJson
  Map<String, dynamic> toJson() => {
        "deviceId": deviceId,
        "locationId": locationId,
        "topicId": topicId,
        "name": name,
      };

  // copyWith
  CanvasDevice copyWith({
    String? deviceId,
    String? locationId,
    String? topicId,
    String? name,
  }) {
    return CanvasDevice(
      deviceId: deviceId ?? this.deviceId,
      locationId: locationId ?? this.locationId,
      topicId: topicId ?? this.topicId,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CanvasDevice && deviceId == other.deviceId;
  }
}

class DeviceInfo {
  String deviceId;
  String deviceName;

  DeviceInfo({
    required this.deviceId,
    required this.deviceName,
  });

  // Factory constructor to create an instance from JSON
  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['device_id'] as String,
      deviceName: json['device_name'] as String,
    );
  }

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'device_name': deviceName,
    };
  }
}
