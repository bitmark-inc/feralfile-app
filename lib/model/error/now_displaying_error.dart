import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';

abstract class NowDisplayingException implements Exception {}

class CheckCastingStatusException implements NowDisplayingException {
  CheckCastingStatusException(this.error);

  final ReplyError error;
}

class CannotGetNowDisplayingException implements NowDisplayingException {
  CannotGetNowDisplayingException({this.error});

  final Object? error;

  @override
  String toString() => 'FF1 is connected but cannot get now displaying';
}
