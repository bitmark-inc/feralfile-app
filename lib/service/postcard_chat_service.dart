import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/chat_message.dart' as app;
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/service/chat_auth_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:crypto/crypto.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:libauk_dart/libauk_dart.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PostcardChatService {
  final bool maintainConnection;

  //constructor
  PostcardChatService({required this.maintainConnection});

  WebSocketChannel? _websocketChannel;
  String? _address;
  String? _id;
  Pair<WalletStorage, int>? _wallet;

  Future<void> connect({
    required String address,
    required String id,
    required Pair<WalletStorage, int> wallet,
  }) async {
    log.info("[CHAT] connect: $address, $id");
    if (_address == address &&
        _id == id &&
        _wallet == wallet &&
        _websocketChannel != null) {
      log.info("[CHAT] connect to the same channel. Do nothing");
      return;
    }
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
    await _websocketChannel?.ready;
  }

  void addListener({
    required Function(List<app.Message>) onNewMessages,
    required Function(String messageId, types.Status type) onResponseMessage,
    required Function(List<app.Message> message, String id)
        onResponseMessageReturnPayload,
    required Function() onDoneCalled,
  }) {
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
              onNewMessages(newMessages);
            } catch (e) {
              log.info("[CHAT] NEW_MESSAGE error: $e");
            }
            break;
          case 'RESP':
            if (response.payload["ok"] != null &&
                response.payload["ok"].toString() == "1") {
              onResponseMessage(response.id, types.Status.sent);
            } else if (response.payload["error"] != null) {
              onResponseMessage(response.id, types.Status.error);
            } else {
              try {
                final newMessages =
                    (response.payload["messages"] as List<dynamic>)
                        .map((e) => app.Message.fromJson(e))
                        .toList();

                onResponseMessageReturnPayload(newMessages, response.id);
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
        if (!maintainConnection) return;

        Future.delayed(const Duration(seconds: 5), () async {
          if (_address != null && _id != null && _wallet != null) {
            _address = null;
            _id = null;
            _wallet = null;
            log.info("[CHAT] _websocketChannel reconnecting");
            await connect(
              address: _address!,
              id: _id!,
              wallet: _wallet!,
            );
            addListener(
                onNewMessages: onNewMessages,
                onResponseMessage: onResponseMessage,
                onResponseMessageReturnPayload: onResponseMessageReturnPayload,
                onDoneCalled: onDoneCalled);
            onDoneCalled.call();
          }
        });
      },
    );
  }

  Future<void> disconnect() async {
    log.info("[CHAT] disconnect");
    _address = null;
    _id = null;
    _wallet = null;
    await _websocketChannel?.sink.close();
    _websocketChannel = null;
  }

  void sendMessage(dynamic message) {
    _websocketChannel?.sink.add(message);
  }

  Stream<dynamic>? get stream => _websocketChannel?.stream;

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
    });
    header["Authorization"] = "Bearer $token";
    return header;
  }
}
