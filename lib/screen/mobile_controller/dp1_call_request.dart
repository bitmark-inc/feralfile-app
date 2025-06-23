class DP1CallRequest {
  final Map<String, dynamic> dp1Call;
  final Map<String, dynamic> metadata;

  DP1CallRequest({
    required this.dp1Call,
    required this.metadata,
  });

  factory DP1CallRequest.fromJson(Map<String, dynamic> json) {
    return DP1CallRequest(
      dp1Call: json['dp1_call'] as Map<String, dynamic>,
      metadata: json['metadata'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dp1_call': dp1Call,
      'metadata': metadata,
    };
  }
}
