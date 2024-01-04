import 'package:autonomy_flutter/model/chat_message.dart' as app;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

extension ListMessageExtension on List<app.Message> {
  List<types.Message> get toTypeMessages =>
      map((e) => e.toTypesMessage()).toList();
}
