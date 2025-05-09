import 'dart:convert';

import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

typedef NotificationCallback = void Function(List<String> data);

final statusChangeTopic = 'statusChanged';
final wifiConnectionTopic = 'wifi_connection';
final scanWifiTopic = 'scanWifi';

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
    log.info('[BluetoothNotification] Unsubscribing from topic: $topic');
    _subscribers[topic]?.remove(callback);
    if (_subscribers[topic]?.isEmpty ?? false) {
      _subscribers.remove(topic);
    }
  }

  // get data from raw data
  // i have a byte array, in varint format, now i want to get all the data into a list
  List<String> getDataFromRawData(List<int> data) {
    final reader = ByteDataReader(data);
    final result = <String>[];
    try {
      while (reader.hasMoreData()) {
        final length = reader.readVarint();
        final bytes = reader.read(length);
        final string = utf8.decode(bytes);
        result.add(string);
      }
    } catch (e) {
      log.info('[BluetoothNotification] Error processing raw data: $e');
    }
    return result;
  }

  // Handle incoming notification data
  void handleNotification(List<int> data, BluetoothDevice device) {
    try {
      final list = getDataFromRawData(data);
      // log all item in list using log.info in one line
      log.info('[BluetoothNotification] Notification data: ${list.join(', ')}');

      final topic = list[0];

      final callbacks = _subscribers[topic]?.toList();
      // Notify subscribers
      callbacks?.forEach((callback) {
        try {
          callback(list.sublist(1));
        } catch (e, s) {
          log.info('[BluetoothNotification] Error processing notification: $e');
        }
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

  bool hasMoreData() {
    return _position < _data.length;
  }
}
