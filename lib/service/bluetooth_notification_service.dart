import 'dart:convert';

import 'package:autonomy_flutter/util/log.dart';

typedef NotificationCallback = void Function(Map<String, dynamic> data);

class BluetoothNotificationService {
  // Singleton instance
  static final BluetoothNotificationService _instance =
      BluetoothNotificationService._internal();
  factory BluetoothNotificationService() => _instance;
  BluetoothNotificationService._internal();

  // Map to store topic subscribers
  final Map<String, List<NotificationCallback>> _subscribers = {};

  // Subscribe to a specific topic
  void subscribe(String topic, NotificationCallback callback) {
    _subscribers[topic] ??= [];
    _subscribers[topic]!.add(callback);
  }

  // Unsubscribe from a specific topic
  void unsubscribe(String topic, NotificationCallback callback) {
    _subscribers[topic]?.remove(callback);
    if (_subscribers[topic]?.isEmpty ?? false) {
      _subscribers.remove(topic);
    }
  }

  // Handle incoming notification data
  void handleNotification(List<int> data) {
    try {
      // Create a ByteData view of the notification data
      final reader = ByteDataReader(data);

      // Read first varint for topic length
      final topicLength = reader.readVarint();

      // Read topic string
      final topicBytes = reader.read(topicLength);
      final topic = utf8.decode(topicBytes);

      // Read second varint for JSON data length
      final jsonLength = reader.readVarint();

      // Read JSON data
      final jsonBytes = reader.read(jsonLength);
      final jsonString = utf8.decode(jsonBytes);
      // Parse JSON data
      final Map<String, dynamic> jsonData =
          json.decode(jsonString) as Map<String, dynamic>;

      log.info(
          '[BluetoothNotification] Received notification - Topic: $topic, Data: $jsonData');

      // Notify subscribers
      _subscribers[topic]?.forEach((callback) {
        callback(jsonData);
      });
    } catch (e, s) {
      log.info('[BluetoothNotification] Error processing notification: $e');
    }
  }
}

// Helper class to read bytes with varint support
class ByteDataReader {
  final List<int> _data;
  int _position = 0;

  ByteDataReader(this._data);

  int readVarint() {
    var result = 0;
    var shift = 0;

    while (true) {
      final byte = _data[_position++];
      result |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }

    return result;
  }

  List<int> read(int length) {
    final result = _data.sublist(_position, _position + length);
    _position += length;
    return result;
  }
}
