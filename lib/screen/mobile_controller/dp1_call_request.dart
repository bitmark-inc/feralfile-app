class DP1CallRequest {
  final Map<String, dynamic> dp1Call;
  final Map<String, dynamic> intent;

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

  Map<String, dynamic> toJson() {
    return {
      'dp1_call': dp1Call,
      'intent': intent,
    };
  }
}

abstract class DP1CallBase {
  // contructor
  DP1CallBase();

  // toJson
  Map<String, dynamic> toJson();
}

abstract class DP1IntentBase {
  Map<String, dynamic> toJson();
}

// class DP1CallRequest {
//   DP1CallRequest({
//     required this.dp1Call,
//     required this.intent,
//   });
//
//   /// Add factory method with constructor functions passed in
//   factory DP1CallRequest.fromJson(
//     Map<String, dynamic> json, {
//     required DP1CallBase Function(Map<String, dynamic>) callFromJson,
//     required DP1IntentBase Function(Map<String, dynamic>) intentFromJson,
//   }) {
//     return DP1CallRequest(
//       dp1Call: callFromJson(json['dp1_call'] as Map<String, dynamic>),
//       intent: intentFromJson(json['intent'] as Map<String, dynamic>),
//     );
//   }
//
//   final DP1CallBase dp1Call;
//   final DP1IntentBase intent;
//
//   Map<String, dynamic> toJson() {
//     return {
//       'dp1_call': dp1Call.toJson(),
//       'intent': intent.toJson(),
//     };
//   }
// }
