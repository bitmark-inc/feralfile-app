import 'dart:convert';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/chat/chat_state.dart';
import 'package:autonomy_flutter/service/chat_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/log.dart';

class AuChatBloc extends AuBloc<AuChatEvent, AuChatState> {
  final ChatService _chatService;

  AuChatBloc(this._chatService) : super(AuChatState()) {
    on<GetAliasesEvent>((event, emit) async {
      final assetToken = event.assetToken;
      final wallet = await assetToken.getOwnerWallet();
      if (wallet == null) {
        log.info('[AuChatBloc] Wallet is null');
        emit(state.copyWith(aliases: []));
        return;
      }
      final aliases =
          await _chatService.getAliases(indexId: assetToken.id, wallet: wallet);
      emit(state.copyWith(aliases: aliases));
    });

    on<SetChatAliasEvent>((event, emit) async {
      final assetToken = event.assetToken;
      final wallet = await assetToken.getOwnerWallet();
      final address = assetToken.owner;
      if (wallet == null) {
        log.info('[AuChatBloc] Wallet is null');
        return;
      }
      await _chatService.setAlias(
          indexId: assetToken.id,
          address: address,
          alias: event.alias,
          wallet: wallet);
      add(GetAliasesEvent(assetToken));
    });

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
