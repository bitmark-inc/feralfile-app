import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';

class DP1CallRequest extends FF1Request {
  DP1CallRequest({
    required this.dp1Call,
    required this.intent,
  });

  factory DP1CallRequest.fromJson(Map<String, dynamic> json) {
    return DP1CallRequest(
      dp1Call: json['dp1_call'] as Map<String, dynamic>,
      intent: json['intent'] as Map<String, dynamic>,
    );
  }

  final Map<String, dynamic> dp1Call;
  final Map<String, dynamic> intent;

  Map<String, dynamic> toJson() {
    return {
      'dp1_call': dp1Call,
      'intent': intent,
    };
  }
}
