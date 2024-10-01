import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';

extension CastExhibitionRequestExt on CastExhibitionRequest {
  String get displayKey => exhibitionId ?? '';
}
