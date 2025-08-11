abstract class BaseDevice {
  const BaseDevice({
    required this.topicId,
    required this.deviceId,
  });

  final String deviceId;

  String get name;

  final String topicId;
}
