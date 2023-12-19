import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

abstract class AuChatEvent {}

class GetAliasesEvent extends AuChatEvent {
  final String tokenId;

  GetAliasesEvent(this.tokenId);
}

class SendMessageEvent extends AuChatEvent {
  final types.SystemMessage message;

  SendMessageEvent(this.message);
}

class SetChatAliasEvent extends AuChatEvent {
  final String tokenId;
  final String address;
  final String alias;

  SetChatAliasEvent(
      {required this.tokenId, required this.alias, required this.address});
}

class SubmitMessageEvent extends AuChatEvent {
  final String text;

  SubmitMessageEvent(this.text);
}

class AuChatState {
  final Map<String, String> aliases;
  final int? lastMessageTimestamp;
  final List<types.Message> messages;

  AuChatState({
    this.aliases = const {},
    this.lastMessageTimestamp,
    List<types.Message>? messages,
  }) : messages = messages ?? [];

  AuChatState copyWith({
    Map<String, String>? aliases,
    int? lastMessageTimestamp,
    List<types.Message>? messages,
  }) =>
      AuChatState(
        aliases: aliases ?? this.aliases,
        lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
        messages: messages ?? this.messages,
      );
}
