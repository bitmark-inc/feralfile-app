import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/chat_message.dart' as app;
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/service/chat_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/chat_messsage_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/postcard_chat.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:uuid/uuid.dart';

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
  late ChatThreadPagePayload _payload;
  int? _lastMessageTimestamp;
  bool _didFetchAllMessages = false;
  String? _historyRequestId;
  int? _chatPrivateBannerTimestamp;
  final ConfigurationService _configurationService =
      injector<ConfigurationService>();
  final ChatService _postcardChatService = injector<ChatService>();
  ChatListener? _chatListener;

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
    final config = _configurationService.getPostcardChatConfig(
        address: _payload.address, id: _payload.token.id);
    _chatPrivateBannerTimestamp = config.firstTimeJoined;
    if (_chatPrivateBannerTimestamp == null) {
      final newConfig = config.copyWith(
          firstTimeJoined: DateTime.now().millisecondsSinceEpoch);
      _configurationService.setPostcardChatConfig(newConfig);
    }
  }

  Future<void> _websocketInitAndFetchHistory() async {
    await _websocketInit();
    _lastMessageTimestamp = DateTime.now().millisecondsSinceEpoch;
    _getHistory();
  }

  Future<void> _websocketInit() async {
    await _postcardChatService.connect(
        address: _payload.address,
        id: _payload.token.id,
        wallet: _payload.wallet);
    _chatListener = ChatListener(
      onNewMessages: _handleNewMessages,
      onResponseMessage: _handleSentMessageResp,
      onResponseMessageReturnPayload: (newMessages, id) {
        _handleNewMessages(newMessages, id: id);
        if (newMessages.length < 100) {
          _didFetchAllMessages = true;
        }
      },
      onDoneCalled: () {
        _resentMessages();
        if (_historyRequestId != null) {
          _getHistory(historyId: _historyRequestId);
        }
      },
      id: const Uuid().v4(),
    );
    _postcardChatService.addListener(_chatListener!);
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
    final id = historyId ?? const Uuid().v4();
    _postcardChatService.sendMessage(
      json.encode({
        "command": "HISTORY",
        "id": id,
        "payload": {
          "lastTimestamp": _lastMessageTimestamp,
        }
      }),
      listenerId: _chatListener?.id,
      requestId: id,
    );
    _historyRequestId = id;
  }

  void _handleNewMessages(List<app.Message> newMessages, {String? id}) {
    if (id != null) {
      if (id == _historyRequestId) {
        _messages.addAll(_convertMessages(newMessages));
        if (newMessages.isNotEmpty) {
          _lastMessageTimestamp = newMessages.last.timestamp;
        } else {
          _lastMessageTimestamp = DateTime.now().millisecondsSinceEpoch;
        }
        _historyRequestId = null;
      }
    } else {
      final otherPeopleMessages = _convertMessages(newMessages);
      otherPeopleMessages
          .removeWhere((element) => element.author.id == _user.id);
      _messages.insertAll(0, otherPeopleMessages);
      _messages.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
    }
    final currentMessageTimestamp =
        _messages.isNotEmpty ? _messages.first.createdAt ?? 0 : 0;
    final newMessageTimestamp =
        newMessages.isNotEmpty ? newMessages.first.timestamp : 0;
    int readTimestamp = max(currentMessageTimestamp, newMessageTimestamp);
    readTimestamp = readTimestamp == 0
        ? DateTime.now().millisecondsSinceEpoch
        : readTimestamp;

    _updateLastMessageReadTimeStamp(readTimestamp + 1);

    if (_chatPrivateBannerTimestamp != null) {
      _messages.removeWhere((element) => element.id == _chatPrivateBannerId);
      int index = _messages.indexWhere((element) =>
          element.createdAt != null &&
          element.createdAt! < _chatPrivateBannerTimestamp!);
      if (index == -1) {
        index = _messages.length;
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
    if (mounted) {
      setState(() {
        _messages;
      });
    }
  }

  Future<void> _updateLastMessageReadTimeStamp(int timestamp) async {
    final oldConfig = _configurationService.getPostcardChatConfig(
        address: _payload.address, id: _payload.token.id);
    if (timestamp > (oldConfig.lastMessageReadTimeStamp ?? 0)) {
      final newConfig = oldConfig.copyWith(lastMessageReadTimeStamp: timestamp);
      await _configurationService.setPostcardChatConfig(newConfig);
    }
  }

  void _handleSentMessageResp(String messageId, String type) {
    final index = _messages.indexWhere((element) => element.id == messageId);
    if (index != -1) {
      setState(() {
        switch (type) {
          case ChatService.SENT:
            _messages[index] = _messages[index].copyWith(
                status: types.Status.sent,
                createdAt: DateTime.now().millisecondsSinceEpoch);
            break;
          case ChatService.ERROR:
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
    if (_chatListener != null) {
      _postcardChatService.removeListener(_chatListener!);
    }
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
                emptyState: const SizedBox(),
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

  Widget _postcardCompleteBuilder(
      BuildContext context, types.SystemMessage message) {
    final totalDistance = widget.payload.token.totalDistance;
    final distanceFormater = DistanceFormatter();
    return _chatPrivateBanner(context,
        text: "postcard_complete_chat_message".tr(namedArgs: {
          'distance': distanceFormater.format(
              distance: totalDistance, withFullName: true),
        }));
  }

  Widget _systemMessageBuilder(types.SystemMessage message) {
    if (message.id == _chatPrivateBannerId) {
      return _chatPrivateBanner(context, text: message.text);
    }
    if (message.isCompletedPostcardMessage) {
      return _postcardCompleteBuilder(context, message);
    }
    final isMe = message.author.id == _user.id;
    final avatarUrl = _getAvatarUrl(message.author.id);
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
                    MessageView(
                      message: message,
                      assetToken: _payload.token,
                    ),
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
    _postcardChatService.sendMessage(json.encode({
      "command": "SEND",
      "id": message.id,
      "payload": {"message": message.text}
    }));
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
    return appMessages.map((e) => e.toTypesMessage()).toList();
  }
}

class ChatThreadPagePayload {
  final AssetToken token;
  Pair<WalletStorage, int> wallet;
  final String address;
  final CryptoType cryptoType;
  final String name;

  ChatThreadPagePayload({
    required this.token,
    required this.wallet,
    required this.address,
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
        width: 41,
        height: 41,
        child: CachedNetworkImage(
          imageUrl: url,
          errorWidget: (context, url, error) {
            return SvgPicture.asset("assets/images/default_avatar.svg");
          },
        ));
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
              const SizedBox(width: 25),
              GestureDetector(
                onTap: () {
                  final trimmedText = _textController.text.trim();
                  if (trimmedText.isNotEmpty) {
                    widget.onSendPressed
                        .call(types.PartialText(text: trimmedText));
                    _textController.clear();
                    setState(() {
                      _isTyping = false;
                    });
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28.0),
                    color: AppColor.auLightGrey,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: SvgPicture.asset(
                    "assets/images/send_arrow.svg",
                    width: 21,
                    height: 21,
                    colorFilter: ui.ColorFilter.mode(
                        _isTyping
                            ? AppColor.primaryBlack
                            : AppColor.auQuickSilver,
                        BlendMode.srcIn),
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

class PostcardChatConfig {
  final String address;
  final String tokenId;
  final int? firstTimeJoined;
  final int? lastMessageReadTimeStamp;

  PostcardChatConfig({
    required this.address,
    required this.tokenId,
    this.firstTimeJoined,
    this.lastMessageReadTimeStamp,
  });

  Map<String, dynamic> toJson() {
    return {
      "address": address,
      "tokenId": tokenId,
      "firstTimeJoined": firstTimeJoined,
      "lastMessageReadTimeStamp": lastMessageReadTimeStamp,
    };
  }

  factory PostcardChatConfig.fromJson(Map<String, dynamic> json) {
    return PostcardChatConfig(
      address: json["address"] as String,
      tokenId: json["tokenId"] as String,
      firstTimeJoined: json["firstTimeJoined"] as int?,
      lastMessageReadTimeStamp: json["lastMessageReadTimeStamp"] as int?,
    );
  }

  //copyWith
  PostcardChatConfig copyWith({
    String? address,
    String? tokenId,
    int? firstTimeJoined,
    int? lastMessageReadTimeStamp,
  }) {
    return PostcardChatConfig(
      address: address ?? this.address,
      tokenId: tokenId ?? this.tokenId,
      firstTimeJoined: firstTimeJoined ?? this.firstTimeJoined,
      lastMessageReadTimeStamp:
          lastMessageReadTimeStamp ?? this.lastMessageReadTimeStamp,
    );
  }
}
