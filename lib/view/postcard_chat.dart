import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/screen/chat/chat_thread_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/chat_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:uuid/uuid.dart';
import 'package:autonomy_flutter/model/chat_message.dart' as app;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class MessagePreview extends StatefulWidget {
  final MessagePreviewPayload payload;

  const MessagePreview({Key? key, required this.payload}) : super(key: key);

  @override
  State<MessagePreview> createState() => _MessagePreviewState();
}

class _MessagePreviewState extends State<MessagePreview> {
  final ChatService _postcardChatService = injector<ChatService>();
  Pair<WalletStorage, int>? _wallet;
  app.Message? _lastMessage;
  late AssetToken _assetToken;
  int _newMessageCount = 0;
  final String _fetchId = const Uuid().v4();
  ChatListener? _chatListener;
  bool _didFetch = false;

  @override
  void initState() {
    super.initState();
    _assetToken = widget.payload.asset;
    _websocketInit();
  }

  Future<void> _websocketInit() async {
    _newMessageCount = 0;
    final wallet = await widget.payload.asset.getOwnerWallet();
    if (wallet == null) {
      return;
    }
    _wallet = wallet;
    final address = widget.payload.asset.owner;
    final id = widget.payload.asset.id;
    await _postcardChatService.connect(
        address: address, id: id, wallet: wallet);
    _chatListener = ChatListener(
      onNewMessages: (newMessages) {
        if (newMessages.isNotEmpty) {
          _refreshLastMessage(newMessages);
        }
      },
      onResponseMessage: (_, __) {},
      onResponseMessageReturnPayload: (newMessages, id) {
        _refreshLastMessage(newMessages);
      },
      onDoneCalled: () {},
      id: const Uuid().v4(),
    );
    _postcardChatService.addListener(_chatListener!);

    _postcardChatService.sendMessage(
      json.encode({
        "command": "HISTORY",
        "id": _fetchId,
        "payload": {
          "lastTimestamp": DateTime.now().millisecondsSinceEpoch,
        }
      }),
      requestId: _fetchId,
      listenerId: _chatListener?.id,
    );
  }

  void _refreshLastMessage(List<app.Message> messages) {
    if (messages.isNotEmpty) {
      final chatConfig = injector<ConfigurationService>().getPostcardChatConfig(
          address: widget.payload.asset.owner, id: widget.payload.asset.id);
      final lastReadMessageTimestamp = chatConfig.lastMessageReadTimeStamp ?? 0;
      int addedNewMessage = messages
          .where((element) => element.timestamp > lastReadMessageTimestamp)
          .toList()
          .length;
      _newMessageCount += addedNewMessage;
      final lastMessageTimestamp = _lastMessage?.timestamp ?? 0;
      if (messages.first.timestamp >= lastMessageTimestamp) {
        _lastMessage = messages.first;
      }
    }
    _didFetch = true;
    if (context.mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: AppColor.white,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _wallet == null
              ? const Row(
                  children: [Spacer()],
                )
              : TappableForwardRowWithContent(
                  padding: const EdgeInsets.all(0),
                  leftWidget: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                              text: "messages".tr(),
                              style: theme.textTheme.moMASans700Black18),
                          TextSpan(
                              text: "        ",
                              style: theme.textTheme.moMASans700Black18),
                          TextSpan(
                            text: _getNewMessageString(_newMessageCount),
                            style: theme.textTheme.moMASans400Black14.copyWith(
                                color: const Color.fromRGBO(236, 100, 99, 1),
                                fontSize: 10),
                          )
                        ]),
                      )
                    ],
                  ),
                  onTap: () async {
                    if (!mounted) return;
                    await Navigator.of(context).pushNamed(
                      ChatThreadPage.tag,
                      arguments: ChatThreadPagePayload(
                          token: _assetToken,
                          wallet: _wallet!,
                          address: _assetToken.owner,
                          cryptoType: _assetToken.blockchain == "ethereum"
                              ? CryptoType.ETH
                              : CryptoType.XTZ,
                          name: _assetToken.title ?? ''),
                    );
                    setState(() {
                      _newMessageCount = 0;
                    });
                  },
                  bottomWidget: _lastMessage == null
                      ? _didFetch
                          ? Text(
                              "no_message_start".tr(),
                              style: theme.textTheme.moMASans400Black12
                                  .copyWith(color: AppColor.auQuickSilver),
                            )
                          : const SizedBox()
                      : Row(
                          children: [
                            Expanded(
                              child: MessageView(
                                message: _lastMessage!.toTypesMessage(),
                                assetToken: _assetToken,
                                text: _lastMessage!.message,
                                expandAll: false,
                                showFullTime: true,
                              ),
                            )
                          ],
                        ),
                ),
        ],
      ),
    );
  }

  String _getNewMessageString(int num) {
    if (num == 0) {
      return "";
    }
    if (num > 99) {
      return "_new".tr(args: ["99+"]);
    }
    return "_new".tr(args: [num.toString()]);
  }

  @override
  void dispose() {
    if (_chatListener != null) {
      _postcardChatService.removeListener(_chatListener!);
    }
    super.dispose();
  }
}

class MessagePreviewPayload {
  final AssetToken asset;

  const MessagePreviewPayload({required this.asset});
}

class MessageView extends StatelessWidget {
  final types.Message message;
  final AssetToken assetToken;
  final String text;
  final bool expandAll;
  final bool showFullTime;

  const MessageView(
      {Key? key,
      required this.message,
      required this.assetToken,
      required this.text,
      this.expandAll = true,
      this.showFullTime = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateTime.fromMillisecondsSinceEpoch(message.createdAt ?? 0);
    return Column(
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
              assetToken.getStamperName(message.author.id),
              style: theme.textTheme.moMASans700Black12,
            ),
            const SizedBox(width: 15),
            Text(
              showFullTime
                  ? getChatDateTimeRepresentation(time)
                  : getLocalTimeOnly(time),
              style: theme.textTheme.moMASans400Black12
                  .copyWith(color: AppColor.auQuickSilver, fontSize: 10),
            ),
          ],
        ),
        Text(
          text,
          style: theme.textTheme.moMASans400Black14,
          overflow: expandAll ? null : TextOverflow.ellipsis,
        )
      ],
    );
  }
}
