import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/chat_message.dart' as app;
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/service/chat_auth_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:crypto/crypto.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:synchronized/synchronized.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class ChatService {
  static const ERROR = "error";
  static const SENT = "sent";

  Future<void> connect({
    required String address,
    required String id,
    required Pair<WalletStorage, int> wallet,
  });

  void addListener(ChatListener listener);

  void removeListener(ChatListener listener);

  void sendMessage(dynamic message, {String? listenerId, String? requestId});

  Future<void> dispose();

  bool isConnecting({required String address, required String id});

  Future<void> reconnect();
}

class ChatServiceImpl implements ChatService {
  final List<ChatListener> _listeners = [];
  final Map<String, String> _pendingRequests = {};

  WebSocketChannel? _websocketChannel;
  String? _address;
  String? _id;
  Pair<WalletStorage, int>? _wallet;
  final _connectLock = Lock();
  dynamic _reconnectCallback;

  @override
  Future<void> connect({
    required String address,
    required String id,
    required Pair<WalletStorage, int> wallet,
  }) async {
    await _connectLock.synchronized(() async {
      if (_address == address && _id == id) {
        log.info("[CHAT] connect to the same channel. Do nothing");
        return;
      }
      await _connect(address: address, id: id, wallet: wallet);
    });
  }

  Future<void> _connect({
    required String address,
    required String id,
    required Pair<WalletStorage, int> wallet,
  }) async {
    try {
      log.info("[CHAT] connect: $address, $id");

      _address = address;
      _id = id;
      _wallet = wallet;
      final link = "/v1/chat/ws?index_id=$id&address=$address";
      final header = await _getHeader(link, wallet, address);
      _websocketChannel = IOWebSocketChannel.connect(
        "${Environment.postcardChatServerUrl}$link",
        headers: header,
        customClient: HttpClient(),
        pingInterval: const Duration(seconds: 50),
      );
      // listen events
      log.info("[CHAT] listen events");
      _websocketChannel?.stream.listen(
        (event) {
          log.info("[CHAT] event: $event");
          final response = app.WebsocketMessage.fromJson(json.decode(event));
          switch (response.command) {
            case 'NEW_MESSAGE':
              try {
                final newMessages = (response.payload["messages"]
                        as List<dynamic>)
                    .map((e) => app.Message.fromJson(e as Map<String, dynamic>))
                    .toList();
                for (var element in _listeners) {
                  element.onNewMessages(newMessages);
                }
              } catch (e) {
                log.info("[CHAT] NEW_MESSAGE error: $e");
              }
              break;
            case 'RESP':
              if (response.payload["ok"] != null &&
                  response.payload["ok"].toString() == "1") {
                for (var element in _listeners) {
                  if (_doCall(requestId: response.id, listenerId: element.id)) {
                    element.onResponseMessage(response.id, ChatService.SENT);
                    _pendingRequests.remove(MapEntry(response.id, element.id));
                  }
                }
              } else if (response.payload["error"] != null) {
                for (var element in _listeners) {
                  if (_doCall(requestId: response.id, listenerId: element.id)) {
                    element.onResponseMessage(response.id, ChatService.ERROR);
                    _pendingRequests.remove(MapEntry(response.id, element.id));
                  }
                }
              } else {
                try {
                  final List<app.Message> newMessages =
                      (response.payload["messages"] as List<dynamic>)
                          .map((e) => app.Message.fromJson(e))
                          .toList();
                  for (var element in _listeners) {
                    if (_doCall(
                        requestId: response.id, listenerId: element.id)) {
                      element.onResponseMessageReturnPayload(
                          newMessages, response.id);
                      _pendingRequests
                          .remove(MapEntry(response.id, element.id));
                    }
                  }
                } catch (e) {
                  log.info("[CHAT page] RESP error: $e");
                }
              }
              break;
            default:
              break;
          }
        },
        onDone: () async {
          log.info("[CHAT] onDone");
          if (_listeners.isEmpty) return;
          Future.delayed(const Duration(seconds: 5), () async {
            if (_address != null && _id != null && _wallet != null) {
              _reconnectCallback = () async {
                log.info("[CHAT] _websocketChannel reconnecting");
                await _connect(
                  address: _address!,
                  id: _id!,
                  wallet: _wallet!,
                );
                for (var element in _listeners) {
                  element.onDoneCalled.call();
                }
              };
              if (memoryValues.isForeground) {
                await reconnect();
              }
            }
          });
        },
      );
      await _websocketChannel?.ready;
    } catch (e) {
      log.info("[CHAT] connect error: $e");
    }
  }

  @override
  void addListener(ChatListener listener) {
    _listeners.add(listener);
  }

  @override
  Future<void> dispose() async {
    log.info("[CHAT] disconnect");
    _address = null;
    _id = null;
    _wallet = null;
    _listeners.clear();
    await _websocketChannel?.sink.close();
    _websocketChannel = null;
  }

  @override
  void sendMessage(dynamic message, {String? listenerId, String? requestId}) {
    log.info("[CHAT] sendMessage: $message");
    _websocketChannel?.sink.add(message);
    if (listenerId != null && requestId != null) {
      _pendingRequests[requestId] = listenerId;
    }
  }

  Future<Map<String, dynamic>> _getHeader(
      String link, Pair<WalletStorage, int> wallet, String address) async {
    final Map<String, dynamic> header = {};
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    header["X-Api-Timestamp"] = timestamp;
    final canonicalString = List<String>.of([
      link,
      "",
      timestamp.toString(),
    ]).join("|");
    final hmacSha256 = Hmac(sha256, utf8.encode(Environment.chatServerHmacKey));
    final digest = hmacSha256.convert(utf8.encode(canonicalString));
    final sig = bytesToHex(digest.bytes);
    header["X-Api-Signature"] = sig;

    final pubKey = await wallet.first.getTezosPublicKey(index: wallet.second);
    final authSig = await injector<TezosService>().signMessage(wallet.first,
        wallet.second, Uint8List.fromList(utf8.encode(timestamp.toString())));
    final token = await injector<ChatAuthService>().getAuthToken({
      "address": address,
      "public_key": pubKey,
      "signature": authSig,
      "timestamp": timestamp
    }, address: address);
    header["Authorization"] = "Bearer $token";
    return header;
  }

  @override
  void removeListener(ChatListener listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty) {
      dispose();
    }
  }

  @override
  bool isConnecting({required String address, required String id}) {
    return _address == address && _id == id;
  }

  bool _doCall({required String requestId, required String listenerId}) {
    if (_pendingRequests.containsKey(requestId)) {
      return listenerId == _pendingRequests[requestId];
    }
    return true;
  }

  @override
  Future<void> reconnect() async {
    await _reconnectCallback?.call();
    _reconnectCallback = null;
  }
}

class ChatListener {
  Function(List<app.Message>) onNewMessages;
  Function(String messageId, String type) onResponseMessage;
  Function(List<app.Message> message, String id) onResponseMessageReturnPayload;
  Function() onDoneCalled;
  final String id;

  ChatListener({
    required this.onNewMessages,
    required this.onResponseMessage,
    required this.onResponseMessageReturnPayload,
    required this.onDoneCalled,
    required this.id,
  });
}
