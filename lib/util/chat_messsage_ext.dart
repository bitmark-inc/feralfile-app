import 'package:flutter_chat_types/flutter_chat_types.dart';

extension ChatMessageExtension on SystemMessage {
  bool get isCompletedPostcardMessage => text == 'postcard_complete';
}
