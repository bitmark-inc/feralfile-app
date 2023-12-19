import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/chat_message.dart' as app;
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/screen/chat/chat_thread_page.dart';
import 'package:autonomy_flutter/service/chat_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/chat_messsage_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:uuid/uuid.dart';

class MessagePreview extends StatefulWidget {
  final MessagePreviewPayload payload;

  const MessagePreview({required this.payload, super.key});

  @override
  State<MessagePreview> createState() => _MessagePreviewState();
}

class _MessagePreviewState extends State<MessagePreview> {
  final ChatService _postcardChatService = injector<ChatService>();
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
    unawaited(_websocketInit());
  }

  Future<void> _websocketInit() async {
    _newMessageCount = 0;
    final address = _assetToken.owner;
    final id = _assetToken.id;
    await _postcardChatService.connect(
        address: address, id: id, wallet: widget.payload.wallet);
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
    _postcardChatService
      ..addListener(_chatListener!)
      ..sendMessage(
        json.encode({
          'command': 'HISTORY',
          'id': _fetchId,
          'payload': {
            'lastTimestamp': DateTime.now().millisecondsSinceEpoch,
          }
        }),
        requestId: _fetchId,
        listenerId: _chatListener?.id,
      );
  }

  void _refreshLastMessage(List<app.Message> messages) {
    if (messages.isNotEmpty) {
      final chatConfig = injector<ConfigurationService>().getPostcardChatConfig(
          address: _assetToken.owner, id: _assetToken.id);
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
      child: TappableForwardRowWithContent(
        padding: const EdgeInsets.all(0),
        leftWidget: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'messages'.tr(),
              style: theme.textTheme.moMASans700Black18,
            ),
            const SizedBox(width: 30),
            Text(_getNewMessageString(_newMessageCount),
                style: theme.textTheme.moMASans400Black14.copyWith(
                    color: const Color.fromRGBO(236, 100, 99, 1),
                    fontSize: 10)),
          ],
        ),
        onTap: () async {
          await Navigator.of(context).pushNamed(
            ChatThreadPage.tag,
            arguments: ChatThreadPagePayload(
                token: _assetToken,
                wallet: widget.payload.wallet,
                address: _assetToken.owner,
                cryptoType: _assetToken.blockchain == 'ethereum'
                    ? CryptoType.ETH
                    : CryptoType.XTZ,
                name: _assetToken.title ?? ''),
          );
          setState(() {
            _newMessageCount = 0;
            _assetToken = widget.payload.getAssetToken() ?? _assetToken;
          });
        },
        bottomWidget: _lastMessage == null
            ? _didFetch
                ? Text(
                    'no_message_start'.tr(),
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
                        expandAll: false,
                        showFullTime: true,
                        aliases: widget.payload.aliases),
                  )
                ],
              ),
      ),
    );
  }

  String _getNewMessageString(int num) {
    if (num == 0) {
      return '';
    }
    if (num > 99) {
      return '_new'.tr(args: ['99+']);
    }
    return '_new'.tr(args: [num.toString()]);
  }
}

class MessagePreviewPayload {
  final AssetToken asset;
  final Pair<WalletStorage, int> wallet;
  final AssetToken? Function() getAssetToken;
  final Map<String, String> aliases;

  const MessagePreviewPayload(
      {required this.asset,
      required this.wallet,
      required this.getAssetToken,
      required this.aliases});
}

class MessageView extends StatelessWidget {
  final types.SystemMessage message;
  final AssetToken assetToken;
  final bool expandAll;
  final bool showFullTime;
  final Map<String, String> aliases;

  const MessageView(
      {required this.message,
      required this.assetToken,
      required this.aliases,
      super.key,
      this.expandAll = true,
      this.showFullTime = false});

  Widget completedPostcardMessageView(BuildContext context) {
    final assetToken = this.assetToken;
    final totalDistance = assetToken.totalDistance;
    final distanceFormater = DistanceFormatter();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'postcard_complete_chat_message'.tr(namedArgs: {
            'distance': distanceFormater.format(
                distance: totalDistance, withFullName: true),
          }),
          style: Theme.of(context).textTheme.moMASans400Black12,
          overflow: expandAll ? null : TextOverflow.ellipsis,
          maxLines: expandAll ? null : 1,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (message.isCompletedPostcardMessage) {
      return completedPostcardMessageView(context);
    }
    final time = DateTime.fromMillisecondsSinceEpoch(message.createdAt ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              message.author.getName(assetToken: assetToken, aliases: aliases),
              style: theme.textTheme.moMASans700Black12,
            ),
            const SizedBox(width: 15),
            Text(
              message.status == types.Status.sending
                  ? 'sending'.tr()
                  : showFullTime
                      ? getChatDateTimeRepresentation(time)
                      : getLocalTimeOnly(time),
              style: theme.textTheme.moMASans400Black12
                  .copyWith(color: AppColor.auQuickSilver, fontSize: 10),
            ),
          ],
        ),
        Text(
          message.text,
          style: theme.textTheme.moMASans400Black14,
          overflow: expandAll ? null : TextOverflow.ellipsis,
          maxLines: expandAll ? null : 1,
        )
      ],
    );
  }
}
