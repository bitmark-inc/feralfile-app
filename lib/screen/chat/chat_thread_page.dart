import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/chat_message.dart';
import 'package:autonomy_flutter/model/chat_message.dart' as app;
import 'package:autonomy_flutter/service/chat_auth_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_svg/svg.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatThreadPage extends StatefulWidget {
  static const String tag = "chat_thread_page";
  final ChatThreadPagePayload payload;

  const ChatThreadPage({Key? key, required this.payload}) : super(key: key);

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  final List<types.Message> _messages = [];
  late types.User _user;
  WebSocketChannel? _websocketChannel;
  late ChatThreadPagePayload _payload;
  int? _lastMessageTimestamp;
  bool _didFetchAllMessages = false;
  String? _historyRequestId;
  bool _isTyping = false;
  bool _stopConnect = false;

  @override
  void initState() {
    super.initState();
    _payload = widget.payload;
    _user = types.User(id: _payload.address);
    _websocketInitAndFetchHistory();
    memoryValues.currentGroupChatId = _payload.tokenId;
  }

  Future<void> _websocketInitAndFetchHistory() async {
    await _websocketInit();
    _lastMessageTimestamp = DateTime.now().millisecondsSinceEpoch;
    _getHistory();
  }

  Future<void> _websocketInit() async {
    final link =
        "/v1/chat/ws?index_id=${_payload.tokenId}&address=${_payload.address}";
    final header = await _getHeader(link);
    _websocketChannel = IOWebSocketChannel.connect(
        "${Environment.postcardChatServerUrl}$link",
        headers: header);
    _websocketChannel?.stream.listen(
      (event) {
        log.info("[CHAT] event: $event");
        final response = WebsocketMessage.fromJson(json.decode(event));
        switch (response.command) {
          case 'NEW_MESSAGE':
            try {
              final newMessages = (response.payload["messages"]
                      as List<dynamic>)
                  .map((e) => app.Message.fromJson(e as Map<String, dynamic>))
                  .toList();
              _handleNewMessages(newMessages);
            } catch (e) {
              log.info("[CHAT] NEW_MESSAGE error: $e");
            }
            break;
          case 'RESP':
            if (response.payload["ok"] != null &&
                response.payload["ok"].toString() == "1") {
              _handleSentMessageResp(response.id, types.Status.sent);
            } else if (response.payload["error"] != null) {
              _handleSentMessageResp(response.id, types.Status.error);
            } else {
              try {
                final newMessages =
                    (response.payload["messages"] as List<dynamic>)
                        .map((e) => app.Message.fromJson(e))
                        .toList();

                _handleNewMessages(newMessages, id: response.id);
                if (newMessages.length < 100) {
                  _didFetchAllMessages = true;
                }
              } catch (e) {
                log.info("[CHAT] RESP error: $e");
              }
            }
            break;
          default:
            break;
        }
      },
      onDone: () async {
        log.info(
            "[CHAT] _websocketChannel disconnected. Reconnect _websocketChannel");
        Future.delayed(const Duration(seconds: 5), () async {
          if (!_stopConnect) {
            await _websocketInit();
            _resentMessages();
            if (_historyRequestId != null) {
              _getHistory(historyId: _historyRequestId);
            }
          }
        });
      },
    );
  }

  void _resentMessages() {
    final unsentMessages = _messages
        .where((element) => element.status == types.Status.sending)
        .toList();
    if (unsentMessages.isEmpty) return;
    unsentMessages.sort((a, b) => a.createdAt!.compareTo(b.createdAt!));
    for (var element in unsentMessages) {
      _sendMessage(element as types.TextMessage);
    }
  }

  void _getHistory({String? historyId}) {
    if (_historyRequestId != null && historyId == null) {
      return;
    }
    log.info(
        "[CHAT] getHistory ${DateTime.fromMillisecondsSinceEpoch(_lastMessageTimestamp!)}");
    final id = historyId ?? const Uuid().v4();
    _websocketChannel?.sink.add(json.encode({
      "command": "HISTORY",
      "id": id,
      "payload": {
        "lastTimestamp": _lastMessageTimestamp,
      }
    }));
    _historyRequestId = id;
  }

  Future<Map<String, dynamic>> _getHeader(String link) async {
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

    final pubKey =
        await _payload.wallet.getTezosPublicKey(index: _payload.index);
    final authSig = await injector<TezosService>().signMessage(_payload.wallet,
        _payload.index, Uint8List.fromList(utf8.encode(timestamp.toString())));
    final token = await injector<ChatAuthService>().getAuthToken({
      "address": _payload.address,
      "public_key": pubKey,
      "signature": authSig,
      "timestamp": timestamp
    });
    header["Authorization"] = "Bearer $token";
    return header;
  }

  void _handleNewMessages(List<app.Message> newMessages, {String? id}) {
    if (id != null && id == _historyRequestId) {
      _messages.addAll(_convertMessages(newMessages));
      _lastMessageTimestamp = newMessages.last.timestamp;
      _historyRequestId = null;
    } else {
      final otherPeopleMessages = _convertMessages(newMessages);
      otherPeopleMessages
          .removeWhere((element) => element.author.id == _user.id);
      _messages.insertAll(0, otherPeopleMessages);
      _messages.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
    }
    setState(() {});
  }

  void _handleSentMessageResp(String messageId, types.Status type) {
    final index = _messages.indexWhere((element) => element.id == messageId);
    if (index != -1) {
      setState(() {
        switch (type) {
          case types.Status.sent:
            _messages[index] =
                _messages[index].copyWith(status: types.Status.sent);
            break;
          case types.Status.error:
            _messages.removeAt(index);
            break;
          default:
            break;
        }
      });
    }
  }

  @override
  void dispose() {
    _websocketChannel?.sink.close();
    _websocketChannel = null;
    _stopConnect = true;
    memoryValues.currentGroupChatId = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColor.primaryBlack,
        appBar: getBackAppBar(
          context,
          title: "${_payload.name}\nChat".trim(),
          onBack: () => Navigator.of(context).pop(),
          isWhite: false,
        ),
        body: Container(
            margin: EdgeInsets.zero,
            child: Chat(
              l10n: ChatL10nEn(
                inputPlaceholder: "write_message".tr(),
              ),
              onMessageVisibilityChanged: _onMessageVisibilityChanged,
              customDateHeaderText: getChatDateTimeRepresentation,
              bubbleBuilder: _bubbleBuilder,
              bubbleRtlAlignment: BubbleRtlAlignment.left,
              isLastPage: false,
              theme: _chatTheme,
              emptyState: const CupertinoActivityIndicator(),
              messages: _messages,
              onSendPressed: _handleSendPressed,
              inputOptions: InputOptions(
                  sendButtonVisibilityMode: SendButtonVisibilityMode.always,
                  onTextChanged: (text) {
                    if (_isTyping && text.trim() == '' ||
                        !_isTyping && text.trim() != '') {
                      setState(() {
                        _isTyping = text.trim() != '';
                      });
                    }
                  }),
              user: types.User(id: const Uuid().v4()),
            )));
  }

  void _onMessageVisibilityChanged(types.Message message, bool visible) {
    if (message == _messages.last && visible && !_didFetchAllMessages) {
      _getHistory();
    }
  }

  _submit(String message) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final messageId = const Uuid().v4();

    final sendingMessage = types.TextMessage(
      id: messageId,
      author: _user,
      createdAt: timestamp,
      text: message,
      status: types.Status.sending,
    );
    setState(() {
      _messages.insert(0, sendingMessage);
    });

    _sendMessage(sendingMessage);
    setState(() {
      _isTyping = false;
    });
  }

  _sendMessage(types.TextMessage message) {
    _websocketChannel?.sink.add(json.encode({
      "command": "SEND",
      "id": message.id,
      "payload": {"message": message.text}
    }));
  }

  Widget _bubbleBuilder(
    Widget child, {
    required types.Message message,
    required nextMessageInGroup,
  }) {
    final theme = Theme.of(context);
    if (message is types.TextMessage) {
      final body = message.text;
      String you = "";
      if (message.author.id == _user.id) {
        you = " (${"you".tr()})";
      }
      final time = message.createdAt ?? 0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                message.status == types.Status.sending
                    ? Row(
                        children: [
                          redDotIcon(color: AppColor.auSuperTeal),
                          const SizedBox(width: 8),
                        ],
                      )
                    : const SizedBox(),
                Text(
                  "${message.author.id.maskOnly(3)}$you",
                  style: theme.textTheme.ppMori700White12,
                ),
                const SizedBox(width: 8),
                Text(
                  getChatDateTimeRepresentation(
                      DateTime.fromMillisecondsSinceEpoch(time)),
                  style: theme.textTheme.ppMori400Grey12,
                ),
              ],
            ),
            Text(body, style: theme.textTheme.ppMori400White14),
          ],
        ),
      );
    }
    return child;
  }

  DefaultChatTheme get _chatTheme {
    final theme = Theme.of(context);
    return DefaultChatTheme(
      messageInsetsVertical: 14,
      messageInsetsHorizontal: 14,
      inputPadding: const EdgeInsets.fromLTRB(0, 24, 0, 40),
      backgroundColor: Colors.transparent,
      inputBackgroundColor: theme.colorScheme.primary,
      inputTextStyle: theme.textTheme.ppMori400White14,
      inputTextColor: theme.colorScheme.secondary,
      inputBorderRadius: BorderRadius.zero,
      inputContainerDecoration: BoxDecoration(
        color: theme.colorScheme.primary,
        border: const Border(
          top: BorderSide(
            color: AppColor.auQuickSilver,
            width: 0.5,
          ),
        ),
      ),
      sendButtonIcon: SvgPicture.asset(_isTyping
          ? "assets/images/sendMessageFilled.svg"
          : "assets/images/sendMessage.svg"),
      inputTextCursorColor: theme.colorScheme.secondary,
      emptyChatPlaceholderTextStyle: theme.textTheme.ppMori400White14
          .copyWith(color: AppColor.auQuickSilver),
      dateDividerMargin: const EdgeInsets.symmetric(vertical: 12),
      dateDividerTextStyle: ResponsiveLayout.isMobile
          ? theme.textTheme.dateDividerTextStyle
          : theme.textTheme.dateDividerTextStyle14,
      primaryColor: Colors.transparent,
      sentMessageBodyTextStyle: ResponsiveLayout.isMobile
          ? theme.textTheme.sentMessageBodyTextStyle
          : theme.textTheme.sentMessageBodyTextStyle16,
      secondaryColor: AppColor.chatSecondaryColor,
      receivedMessageBodyTextStyle: ResponsiveLayout.isMobile
          ? theme.textTheme.receivedMessageBodyTextStyle
          : theme.textTheme.receivedMessageBodyTextStyle16,
      receivedMessageDocumentIconColor: Colors.transparent,
      sentMessageDocumentIconColor: Colors.transparent,
      sentMessageCaptionTextStyle: ResponsiveLayout.isMobile
          ? theme.textTheme.sentMessageCaptionTextStyle
          : theme.textTheme.sentMessageCaptionTextStyle16,
      receivedMessageCaptionTextStyle: ResponsiveLayout.isMobile
          ? theme.textTheme.receivedMessageCaptionTextStyle
          : theme.textTheme.receivedMessageCaptionTextStyle16,
    );
  }

  void _handleSendPressed(types.PartialText message) async {
    _submit(message.text);
  }

  List<types.Message> _convertMessages(List<app.Message> appMessages) {
    return appMessages.map((e) => _convertAppMessage(e)).toList();
  }

  types.TextMessage _convertAppMessage(app.Message message,
      {types.Status status = types.Status.sent}) {
    return types.TextMessage(
      id: message.id,
      author: types.User(id: message.sender),
      createdAt: message.timestamp,
      text: message.message,
      status: status,
    );
  }
}

class ChatThreadPagePayload {
  final String tokenId;
  final WalletStorage wallet;
  final String address;
  final int index;
  final CryptoType cryptoType;
  final String name;

  ChatThreadPagePayload({
    required this.tokenId,
    required this.wallet,
    required this.address,
    required this.index,
    required this.cryptoType,
    required this.name,
  });
}
