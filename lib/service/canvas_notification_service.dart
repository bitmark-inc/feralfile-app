import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_notification.dart';
import 'package:autonomy_flutter/model/device/base_device.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class CanvasNotificationService {
  CanvasNotificationService(this._device);

  WebSocketChannel? _channel;
  final _notificationController =
      StreamController<NotificationRelayerMessage>.broadcast();
  final _authService = injector<AuthService>();
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  String? _lastError;

  // basedevice
  final BaseDevice _device;

  Stream<NotificationRelayerMessage> get notificationStream =>
      _notificationController.stream;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final userId = _authService.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final apiKey = Environment.tvKey;
      final topicId = _device.topicId;
      final clientId = userId;

      final wsUrl = '${Environment.tvNotificationUrl}/api/notification?'
          'apiKey=$apiKey&topicID=$topicId&clientId=$clientId';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        _handleMessage,
        onError: (Object error) {
          _handleError(error);
        },
        onDone: _handleDisconnect,
      );

      _isConnected = true;
      _startPingTimer();
      _lastError = null;
    } catch (e) {
      _lastError = e.toString();
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      log.info(
          '[CanvasNotificationService] Device ${_device.name} received message: $message');
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final notification = NotificationRelayerMessage.fromJson(data);
      _notificationController.add(notification);
    } catch (e) {
      log.info('Error parsing notification: $e');
    }
  }

  void _handleError(dynamic error) {
    log.info('WebSocket error: $error');
    _lastError = error.toString();
    _handleDisconnect();
  }

  void _handleDisconnect() {
    _isConnected = false;
    _stopPingTimer();
    _scheduleReconnect();
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _sendPing();
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), connect);
  }

  void _sendPing() {
    if (_isConnected) {
      _channel?.sink.add(jsonEncode({'type': 'ping'}));
    }
  }

  Future<void> disconnect() async {
    _stopPingTimer();
    _reconnectTimer?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  bool get isConnected => _isConnected;

  String? get lastError => _lastError;
}
