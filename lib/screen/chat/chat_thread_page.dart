import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/chat_message.dart';
import 'package:autonomy_flutter/model/chat_message.dart' as app;
import 'package:autonomy_flutter/service/chat_auth_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/models/asset_token.dart';
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
  bool _stopConnect = false;
  late int? _chatPrivateBannerTimestamp;

  @override
  void initState() {
    super.initState();
    _payload = widget.payload;
    _user = types.User(id: _payload.address);
    _websocketInitAndFetchHistory();
    memoryValues.currentGroupChatId = _payload.token.id;
    _checkReadPrivateChatBanner();
  }

  void _checkReadPrivateChatBanner() {
    _chatPrivateBannerTimestamp = injector<ConfigurationService>()
        .getShowedPostcardChatBanner(
            "${_payload.token.id}||${_payload.address}");
  }

  Future<void> _websocketInitAndFetchHistory() async {
    await _websocketInit();
    _lastMessageTimestamp = DateTime.now().millisecondsSinceEpoch;
    _getHistory();
  }

  Future<void> _websocketInit() async {
    final link =
        "/v1/chat/ws?index_id=${_payload.token.id}&address=${_payload.address}";
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
    unsentMessages
        .sort((a, b) => (a.createdAt ?? 0).compareTo(b.createdAt ?? 0));
    for (var element in unsentMessages) {
      _sendMessage(element as types.SystemMessage);
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
    if (_chatPrivateBannerTimestamp != null) {
      _messages.removeWhere((element) => element.id == _chatPrivateBannerId);
      int index = _messages.indexWhere((element) =>
          element.createdAt != null &&
          element.createdAt! < _chatPrivateBannerTimestamp!);
      if (index == -1) {
        index = 0;
      }
      _messages.insert(
          index,
          types.SystemMessage(
            id: _chatPrivateBannerId,
            author: _user,
            createdAt: _chatPrivateBannerTimestamp!,
            text: "chat_is_private".tr(),
            status: types.Status.delivered,
          ));
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
    final theme = Theme.of(context);
    return Scaffold(
        backgroundColor: AppColor.white,
        appBar: getBackAppBar(
          context,
          title: "messages".tr(),
          titleStyle: theme.textTheme.moMASans700Black18,
          onBack: () => Navigator.of(context).pop(),
        ),
        body: Container(
            margin: EdgeInsets.zero,
            child: Chat(
                l10n: ChatL10nEn(
                  inputPlaceholder: "message".tr(),
                ),
                onMessageVisibilityChanged: _onMessageVisibilityChanged,
                customDateHeaderText: getChatDateTimeRepresentation,
                systemMessageBuilder: _systemMessageBuilder,
                bubbleRtlAlignment: BubbleRtlAlignment.left,
                isLastPage: false,
                theme: _chatTheme,
                dateHeaderThreshold: 12 * 60 * 60 * 1000,
                groupMessagesThreshold: DateTime.now().millisecondsSinceEpoch,
                emptyState: const CupertinoActivityIndicator(),
                messages: _messages,
                onSendPressed: (_) {},
                user: types.User(id: const Uuid().v4()),
                customBottomWidget: Column(
                  children: [
                    _chatPrivateBannerTimestamp == null
                        ? _chatPrivateBanner(context)
                        : const SizedBox(),
                    AuInputChat(
                      onSendPressed: _handleSendPressed,
                    ),
                  ],
                ))));
  }

  String _getAvatarUrl(String address) {
    final artists = widget.payload.token.getArtists;
    final artist = artists.firstWhereOrNull((element) => element.id == address);
    if (artists.isEmpty || artist == null) {
      return "";
    }
    String index = artists.indexOf(artist).toString();
    if (index.length == 1) {
      index = "0$index";
    }
    return "${widget.payload.token.getPreviewUrl()}/assets/stamps/$index.png";
  }

  void _onMessageVisibilityChanged(types.Message message, bool visible) {
    if (message == _messages.last && visible && !_didFetchAllMessages) {
      _getHistory();
    }
  }

  Widget _chatPrivateBanner(BuildContext context, {String? text}) {
    final theme = Theme.of(context);
    return Container(
      color: AppColor.momaGreen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 60),
        child: Text(
          text ?? "chat_is_private".tr(),
          textAlign: TextAlign.center,
          style: theme.textTheme.moMASans400Black12,
        ),
      ),
    );
  }

  Widget _systemMessageBuilder(types.SystemMessage message) {
    if (message.id == _chatPrivateBannerId) {
      return _chatPrivateBanner(context, text: message.text);
    }
    final theme = Theme.of(context);
    final isMe = message.author.id == _user.id;
    final avatarUrl = _getAvatarUrl(message.author.id);
    final time = message.createdAt ?? 0;
    return Column(
      children: [
        addOnlyDivider(color: AppColor.auLightGrey),
        Container(
          padding: const EdgeInsets.all(20),
          color: isMe ? AppColor.secondaryDimGreyBackground : AppColor.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              UserAvatar(key: Key(avatarUrl), url: avatarUrl),
              const SizedBox(width: 20),
              Expanded(
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
                          _getStamperName(message.author.id),
                          style: theme.textTheme.moMASans700Black12,
                        ),
                        const SizedBox(width: 15),
                        Text(
                          getChatDateTimeRepresentation(
                              DateTime.fromMillisecondsSinceEpoch(time)),
                          style: theme.textTheme.moMASans400Black12.copyWith(
                              color: AppColor.auQuickSilver, fontSize: 10),
                        ),
                      ],
                    ),
                    Text(
                      message.text,
                      style: theme.textTheme.moMASans400Black14,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _submit(String message) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final messageId = const Uuid().v4();

    final sendingMessage = types.SystemMessage(
      id: messageId,
      author: _user,
      createdAt: timestamp,
      text: message,
      status: types.Status.sending,
    );
    if (_chatPrivateBannerTimestamp == null) {
      _checkReadPrivateChatBanner();
    }
    setState(() {
      _messages.insert(0, sendingMessage);
    });

    _sendMessage(sendingMessage);
  }

  _sendMessage(types.SystemMessage message) {
    _websocketChannel?.sink.add(json.encode({
      "command": "SEND",
      "id": message.id,
      "payload": {"message": message.text}
    }));
  }

  String _getStamperName(String address) {
    final artists = widget.payload.token.getArtists;
    final artist = artists.firstWhereOrNull((element) => element.id == address);
    if (artists.isEmpty || artist == null) {
      return "";
    }
    return "Stamper ${artists.indexOf(artist) + 1}";
  }

  DefaultChatTheme get _chatTheme {
    final theme = Theme.of(context);
    return DefaultChatTheme(
      messageInsetsVertical: 14,
      messageInsetsHorizontal: 14,
      backgroundColor: Colors.transparent,
      typingIndicatorTheme: const TypingIndicatorTheme(
        animatedCirclesColor: neutral1,
        animatedCircleSize: 5.0,
        bubbleBorder: BorderRadius.all(Radius.circular(27.0)),
        bubbleColor: Colors.blue,
        countAvatarColor: primary,
        countTextColor: secondary,
        multipleUserTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: neutral2,
        ),
      ),
      emptyChatPlaceholderTextStyle: theme.textTheme.ppMori400Black14
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

  static const _chatPrivateBannerId = "chat_private_banner";

  void _handleSendPressed(types.PartialText message) async {
    _submit(message.text);
  }

  List<types.Message> _convertMessages(List<app.Message> appMessages) {
    return appMessages.map((e) => _convertAppMessage(e)).toList();
  }

  types.Message _convertAppMessage(app.Message message,
      {types.Status status = types.Status.sent}) {
    return types.SystemMessage(
      id: message.id,
      author: types.User(id: message.sender),
      createdAt: message.timestamp,
      text: message.message,
      status: status,
      type: MessageType.system,
    );
  }
}

class ChatThreadPagePayload {
  final AssetToken token;
  final WalletStorage wallet;
  final String address;
  final int index;
  final CryptoType cryptoType;
  final String name;

  ChatThreadPagePayload({
    required this.token,
    required this.wallet,
    required this.address,
    required this.index,
    required this.cryptoType,
    required this.name,
  });
}

class UserAvatar extends StatelessWidget {
  final String url;

  const UserAvatar({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 41, height: 41, child: CachedNetworkImage(imageUrl: url));
  }
}

class AuInputChat extends StatefulWidget {
  final void Function(types.PartialText) onSendPressed;

  const AuInputChat({Key? key, required this.onSendPressed}) : super(key: key);

  @override
  State<AuInputChat> createState() => _AuInputChatState();
}

class _AuInputChatState extends State<AuInputChat> {
  final TextEditingController _textController = TextEditingController();
  bool _isTyping = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        border: const Border(
          top: BorderSide(
            color: AppColor.auQuickSilver,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 20, 15, 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: theme.textTheme.moMASans400Black14,
                  cursorColor: theme.colorScheme.primary,
                  decoration: InputDecoration(
                      constraints: const BoxConstraints(maxHeight: 200),
                      border: _contentBorder,
                      focusedBorder: _contentBorder,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      hintText: "message".tr(),
                      hintStyle: theme.textTheme.moMASans400Black14.copyWith(
                        color: AppColor.auQuickSilver,
                      ),
                      isDense: true),
                  maxLines: 5,
                  minLines: 1,
                  onChanged: (text) {
                    if (_isTyping && text.trim() == '' ||
                        !_isTyping && text.trim() != '') {
                      setState(() {
                        _isTyping = text.trim() != '';
                      });
                    }
                  },
                  onTap: () {},
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  final trimmedText = _textController.text.trim();
                  if (trimmedText.isNotEmpty) {
                    widget.onSendPressed
                        .call(types.PartialText(text: trimmedText));
                    _textController.clear();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28.0),
                    color: AppColor.auLightGrey,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: AnimatedDefaultTextStyle(
                    style: theme.textTheme.ppMori400Black14.copyWith(
                        color: _isTyping ? null : AppColor.auQuickSilver),
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      "send".tr(),
                    ),
                  ),
                ),
              )
            ],
          )),
    );
  }

  final _contentBorder = const OutlineInputBorder(
      borderSide: BorderSide(color: AppColor.auQuickSilver),
      borderRadius: BorderRadius.all(Radius.circular(28)));

  @override
  void dispose() {
    _textController.dispose();
    FocusManager.instance.primaryFocus?.unfocus();
    super.dispose();
  }
}
