import 'package:autonomy_flutter/gateway/chat_api.dart';

extension ListChatAliasExt on List<ChatAlias> {
  String? getAlias(String address) {
    for (final alias in this) {
      if (alias.address == address) {
        return alias.alias;
      }
    }
    return null;
  }

  bool isHasAlias(String address) => any(
        (element) => element.address == address,
      );
}
