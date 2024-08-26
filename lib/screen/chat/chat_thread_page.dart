import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/chat_api.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/chat_message.dart' as app;
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/screen/chat/chat_bloc.dart';
import 'package:autonomy_flutter/screen/chat/chat_state.dart';
import 'package:autonomy_flutter/service/chat_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/chat_alias_ext.dart';
import 'package:autonomy_flutter/util/chat_messsage_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/message_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/loading.dart';
import 'package:autonomy_flutter/view/postcard_chat.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/extensions/theme_extension/moma_sans.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
//ignore: implementation_imports
import 'package:flutter_chat_ui/src/models/date_header.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:uuid/uuid.dart';

class ChatThreadPage extends StatefulWidget {
  final ChatThreadPagePayload payload;

  const ChatThreadPage({required this.payload, super.key});

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
  final ConfigurationService _configurationService =
      injector<ConfigurationService>();
  final ChatService _postcardChatService = injector<ChatService>();
  ChatListener? _chatListener;
  late AuChatBloc _auChatBloc;
  List<ChatAlias>? _aliases;
  late TextEditingController _textController;
  late FocusNode _textFieldFocusNode;
  late bool _showSetAliasTextField;
  late bool _withOverlay;

  @override
  void initState() {
    super.initState();
    _payload = widget.payload;
    _user = types.User(id: _payload.address);
    unawaited(_websocketInitAndFetchHistory());
    memoryValues.currentGroupChatId = _payload.token.id;
    _textController = TextEditingController();
    _textFieldFocusNode = FocusNode();
    _withOverlay = _textFieldFocusNode.hasFocus;
    _textFieldFocusNode.addListener(_textFieldFocusNodeListener);
    _showSetAliasTextField = false;
    _auChatBloc = injector<AuChatBloc>();
    _auChatBloc.add(GetAliasesEvent(_payload.token));
  }

  void _textFieldFocusNodeListener() {
    setState(() {
      _withOverlay = _textFieldFocusNode.hasFocus;
    });
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
    if (unsentMessages.isEmpty) {
      return;
    }
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
        'command': 'HISTORY',
        'id': id,
        'payload': {
          'lastTimestamp': _lastMessageTimestamp,
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
        _messages.addAll(newMessages.toTypeMessages);
        if (newMessages.isNotEmpty) {
          _lastMessageTimestamp = newMessages.last.timestamp;
        } else {
          _lastMessageTimestamp = DateTime.now().millisecondsSinceEpoch;
        }
        _historyRequestId = null;
      }
    } else {
      final otherPeopleMessages = newMessages.toTypeMessages
        ..removeWhere((element) => element.author.id == _user.id);
      _messages
        ..insertAll(0, otherPeopleMessages)
        ..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
    }
    final currentMessageTimestamp =
        _messages.isNotEmpty ? _messages.first.createdAt ?? 0 : 0;
    final newMessageTimestamp =
        newMessages.isNotEmpty ? newMessages.first.timestamp : 0;
    int readTimestamp = max(currentMessageTimestamp, newMessageTimestamp);
    readTimestamp = readTimestamp == 0
        ? DateTime.now().millisecondsSinceEpoch
        : readTimestamp;

    unawaited(_updateLastMessageReadTimeStamp(readTimestamp + 1));

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
      unawaited(_postcardChatService.removeListener(_chatListener!));
    }
    memoryValues.currentGroupChatId = null;
    _textController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  void onSubmitAlias(String alias) {
    setState(() {
      _showSetAliasTextField = false;
    });
    if (alias.trim().isEmpty) {
      return;
    }
    _auChatBloc
        .add(SetChatAliasEvent(assetToken: widget.payload.token, alias: alias));
  }

  Widget _setAliasTextField(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _textController,
      focusNode: _textFieldFocusNode,
      onSubmitted: onSubmitAlias,
      style: theme.textTheme.moMASans700Black16.copyWith(fontSize: 18),
      cursorColor: theme.colorScheme.primary,
      decoration: InputDecoration(
        constraints: const BoxConstraints(maxHeight: 56),
        contentPadding: const EdgeInsets.all(15),
        border: InputBorder.none,
        hintText:
            !_textFieldFocusNode.hasFocus ? 'set_a_chat_alias'.tr() : null,
        hintStyle: theme.textTheme.moMASans700Black16.copyWith(fontSize: 18),
        isDense: true,
        fillColor: AppColor.auLightGrey,
        filled: true,
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      cursorWidth: 1,
      textAlignVertical: TextAlignVertical.center,
      textAlign: TextAlign.center,
      textCapitalization: TextCapitalization.sentences,
      onTapOutside: (event) {
        if (!_textFieldFocusNode.hasFocus) {
          return;
        }
        _textFieldFocusNode.unfocus();
        onSubmitAlias(_textController.text);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<AuChatBloc, AuChatState>(
        bloc: _auChatBloc,
        builder: (context, chatState) => Scaffold(
              backgroundColor: POSTCARD_BACKGROUND_COLOR,
              appBar: getBackAppBar(
                context,
                title: 'messages'.tr(),
                titleStyle: theme.textTheme.moMASans700Black18,
                onBack: () => Navigator.of(context).pop(),
                statusBarColor: POSTCARD_BACKGROUND_COLOR,
                backgroundColor: POSTCARD_BACKGROUND_COLOR,
              ),
              body: _aliases != null
                  ? Column(
                      children: [
                        if (_showSetAliasTextField)
                          Container(
                            color: Colors.transparent,
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                children: [
                                  _setAliasTextField(context),
                                ],
                              ),
                            ),
                          ),
                        Expanded(
                          child: Stack(
                            children: [
                              _chatThread(context),
                              if (_withOverlay)
                                Positioned.fill(
                                    child: Container(
                                  color: Colors.white.withOpacity(0.9),
                                ))
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(),
            ),
        listener: (context, chatState) {
          setState(() {
            _aliases = chatState.aliases;
            final alias = chatState.aliases?.getAlias(_payload.address);
            _showSetAliasTextField = alias == null;
            if (alias != null) {
              _textController.text = alias;
            }
          });
        });
  }

  void _onMessageVisibilityChanged(types.Message message, bool visible) {
    if (message == _messages.last && visible && !_didFetchAllMessages) {
      _getHistory();
    }
  }

  void _onTapToSetAlias() {
    setState(() {
      _textFieldFocusNode.requestFocus();
      _showSetAliasTextField = true;
    });
  }

  Widget _dateHeaderBuilder(BuildContext context, DateHeader date) {
    final theme = Theme.of(context);
    if (date.dateTime.millisecondsSinceEpoch ==
        chatPrivateBannerMessage.createdAt) {
      return const SizedBox();
    } else {
      return Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          date.text,
          style: ResponsiveLayout.isMobile
              ? theme.textTheme.dateDividerTextStyle
              : theme.textTheme.dateDividerTextStyle14,
        ),
      );
    }
  }

  Widget _chatThread(BuildContext context) => Chat(
        l10n: ChatL10nEn(
          inputPlaceholder: 'message'.tr(),
        ),
        onMessageVisibilityChanged: _onMessageVisibilityChanged,
        customDateHeaderText: getChatDateTimeRepresentation,
        systemMessageBuilder: (systemMessage) => _systemMessageBuilder(
          message: systemMessage,
          onAvatarTap: () {},
          onAliasTap: () {
            if (_user.id != systemMessage.author.id) {
              return;
            }
            _onTapToSetAlias();
          },
        ),
        bubbleRtlAlignment: BubbleRtlAlignment.left,
        isLastPage: false,
        theme: _chatTheme,
        dateHeaderThreshold: 12 * 60 * 60 * 1000,
        groupMessagesThreshold: DateTime.now().millisecondsSinceEpoch,
        dateHeaderBuilder: (DateHeader date) =>
            _dateHeaderBuilder(context, date),
        emptyState: const SizedBox(),
        messages: _messages.insertBannerMessage(),
        onSendPressed: (_) {},
        user: types.User(id: const Uuid().v4()),
        customBottomWidget: Column(
          children: [
            AuInputChat(
              onSendPressed: _handleSendPressed,
            ),
          ],
        ),
      );

  Widget _chatPrivateBanner(BuildContext context, {String? text}) {
    final theme = Theme.of(context);
    return Container(
      color: AppColor.momaGreen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 60),
        child: Text(
          text ?? 'chat_is_private'.tr(),
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
        text: 'postcard_complete_chat_message'.tr(namedArgs: {
          'distance': distanceFormater.format(
              distance: totalDistance, withFullName: true),
        }));
  }

  Widget _systemMessageBuilder({
    required types.SystemMessage message,
    required void Function()? onAvatarTap,
    required void Function()? onAliasTap,
  }) {
    if (message.isPrivateChatMessage) {
      return _chatPrivateBanner(context, text: message.text);
    }
    if (message.isCompletedPostcardMessage) {
      return _postcardCompleteBuilder(context, message);
    }

    final isMe = message.author.id == _user.id;
    final assetToken = _payload.token;
    final avatarUrl = message.author.getAvatarUrl(assetToken: assetToken);
    final backgroundColor = isMe || message.isSystemMessage
        ? AppColor.secondaryDimGreyBackground
        : POSTCARD_BACKGROUND_COLOR;
    return Column(
      children: [
        addOnlyDivider(color: AppColor.auLightGrey),
        Container(
          padding: const EdgeInsets.all(15),
          color: backgroundColor,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: (message.isSystemMessage)
                    ? SystemUserAvatar(
                        url: avatarUrl,
                        key: Key(avatarUrl),
                      )
                    : UserAvatar(key: Key(avatarUrl), url: avatarUrl),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MessageView(
                      message: message,
                      assetToken: assetToken,
                      aliases: _aliases!,
                      onAliasTap: onAliasTap,
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

  void _submit(String message) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final messageId = const Uuid().v4();

    final sendingMessage = types.SystemMessage(
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
  }

  void _sendMessage(types.SystemMessage message) {
    _auChatBloc.add(SendMessageEvent(message));
  }

  DefaultChatTheme get _chatTheme {
    final theme = Theme.of(context);
    return DefaultChatTheme(
      messageInsetsVertical: 0,
      messageInsetsHorizontal: 0,
      backgroundColor: Colors.transparent,
      typingIndicatorTheme: const TypingIndicatorTheme(
        animatedCirclesColor: neutral1,
        animatedCircleSize: 5,
        bubbleBorder: BorderRadius.all(Radius.circular(27)),
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

  void _handleSendPressed(types.PartialText message) {
    _submit(message.text);
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

  const UserAvatar({required this.url, super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
      width: 41,
      height: 41,
      child: CachedNetworkImage(
        imageUrl: url,
        errorWidget: (context, url, error) =>
            SvgPicture.asset('assets/images/default_avatar.svg'),
        placeholder: (context, url) {
          return LoadingWidget();
        },
      ));
}

class SystemUserAvatar extends UserAvatar {
  const SystemUserAvatar({required super.url, super.key});

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 41, height: 41, child: SvgPicture.asset(url));
}

class AuInputChat extends StatefulWidget {
  final void Function(types.PartialText) onSendPressed;

  const AuInputChat({required this.onSendPressed, super.key});

  @override
  State<AuInputChat> createState() => _AuInputChatState();
}

class _AuInputChatState extends State<AuInputChat> {
  final TextEditingController _textController = TextEditingController();
  bool _isTyping = false;

  Widget _sendIcon(BuildContext context) => SvgPicture.asset(
        'assets/images/sendMessage.svg',
        width: 22,
        height: 22,
        colorFilter: ui.ColorFilter.mode(
            _isTyping ? AppColor.primaryBlack : AppColor.auQuickSilver,
            BlendMode.srcIn),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
      ),
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
                  constraints: const BoxConstraints(maxHeight: 24),
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: 'write_a_message'.tr(),
                  hintStyle: theme.textTheme.moMASans400Black14.copyWith(
                    color: AppColor.auQuickSilver,
                  ),
                  isDense: true),
              cursorWidth: 1,
              textAlignVertical: TextAlignVertical.center,
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
          const SizedBox(width: 57),
          GestureDetector(
            onTap: () {
              final trimmedText = _textController.text.trim();
              if (trimmedText.isNotEmpty) {
                widget.onSendPressed.call(types.PartialText(text: trimmedText));
                _textController.clear();
                setState(() {
                  _isTyping = false;
                });
              }
            },
            child: _sendIcon(context),
          )
        ],
      ),
    );
  }

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
  final int? lastMessageReadTimeStamp;

  PostcardChatConfig({
    required this.address,
    required this.tokenId,
    this.lastMessageReadTimeStamp,
  });

  Map<String, dynamic> toJson() => {
        'address': address,
        'tokenId': tokenId,
        'lastMessageReadTimeStamp': lastMessageReadTimeStamp,
      };

  factory PostcardChatConfig.fromJson(Map<String, dynamic> json) =>
      PostcardChatConfig(
        address: json['address'] as String,
        tokenId: json['tokenId'] as String,
        lastMessageReadTimeStamp: json['lastMessageReadTimeStamp'] as int?,
      );

  //copyWith
  PostcardChatConfig copyWith({
    String? address,
    String? tokenId,
    int? firstTimeJoined,
    int? lastMessageReadTimeStamp,
  }) =>
      PostcardChatConfig(
        address: address ?? this.address,
        tokenId: tokenId ?? this.tokenId,
        lastMessageReadTimeStamp:
            lastMessageReadTimeStamp ?? this.lastMessageReadTimeStamp,
      );
}
