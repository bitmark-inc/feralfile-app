import 'package:autonomy_flutter/gateway/chat_api.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:nft_collection/models/asset_token.dart';

abstract class AuChatEvent {}

class GetAliasesEvent extends AuChatEvent {
  final AssetToken assetToken;

  GetAliasesEvent(this.assetToken);
}

class SendMessageEvent extends AuChatEvent {
  final types.SystemMessage message;

  SendMessageEvent(this.message);
}

class SetChatAliasEvent extends AuChatEvent {
  final AssetToken assetToken;
  final String alias;

  SetChatAliasEvent({required this.assetToken, required this.alias});
}

class SubmitMessageEvent extends AuChatEvent {
  final String text;

  SubmitMessageEvent(this.text);
}

class AuChatState {
  final List<ChatAlias> aliases;
  final int? lastMessageTimestamp;
  final List<types.Message> messages;

  AuChatState({
    this.aliases = const [],
    this.lastMessageTimestamp,
    List<types.Message>? messages,
  }) : messages = messages ?? [];

  AuChatState copyWith({
    List<ChatAlias>? aliases,
    int? lastMessageTimestamp,
    List<types.Message>? messages,
  }) =>
      AuChatState(
        aliases: aliases ?? this.aliases,
        lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
        messages: messages ?? this.messages,
      );
}
