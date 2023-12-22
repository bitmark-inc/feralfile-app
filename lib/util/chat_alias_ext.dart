import 'package:autonomy_flutter/gateway/chat_api.dart';
import 'package:collection/collection.dart';

extension ListChatAliasExt on List<ChatAlias> {
  String? getAlias(String address) =>
      firstWhereOrNull((element) => element.address == address)?.alias;

  bool isHasAlias(String address) => any(
        (element) => element.address == address,
      );
}
