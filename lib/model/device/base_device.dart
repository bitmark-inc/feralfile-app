abstract class BaseDevice {
  const BaseDevice({
    required this.topicId,
  });

  String get deviceId;

  String get name;

  final String topicId;
}
