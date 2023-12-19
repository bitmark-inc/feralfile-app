import 'dart:convert';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/chat/chat_state.dart';
import 'package:autonomy_flutter/service/chat_service.dart';

class AuChatBloc extends AuBloc<AuChatEvent, AuChatState> {
  final ChatService _chatService;

  AuChatBloc(this._chatService) : super(AuChatState()) {
    on<GetAliasesEvent>((event, emit) async {
      final aliases = await _chatService.getAliases(event.tokenId);
      emit(state.copyWith(aliases: aliases));
    });

    on<SetChatAliasEvent>((event, emit) async {
      await _chatService.setAlias(
          tokenId: event.tokenId, address: event.address, alias: event.alias);
      add(GetAliasesEvent(event.tokenId));
    });

    // on<SubmitMessageEvent> ((event, emit) {
    //   final timestamp = DateTime.now().millisecondsSinceEpoch;
    //   final messageId = const Uuid().v4();
    //
    //   final sendingMessage = types.SystemMessage(
    //     id: messageId,
    //     author: _user,
    //     createdAt: timestamp,
    //     text: message,
    //     status: types.Status.sending,
    //   );
    //   if (_chatPrivateBannerTimestamp == null) {
    //     _checkReadPrivateChatBanner();
    //   }
    //   setState(() {
    //     _messages.insert(0, sendingMessage);
    //   });
    //
    //   _auChatBloc.add(SendMessageEvent(sendingMessage));
    //       }

    on<SendMessageEvent>((event, emit) {
      final message = event.message;
      _chatService.sendMessage(json.encode({
        'command': 'SEND',
        'id': message.id,
        'payload': {'message': message.text}
      }));
    });
  }
}
