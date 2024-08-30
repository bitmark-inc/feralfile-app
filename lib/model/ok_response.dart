class OkResponse {
  final int ok;

  OkResponse({required this.ok});

  factory OkResponse.fromJson(Map<String, dynamic> map) => OkResponse(
        ok: map['ok'],
      );

  Map<String, dynamic> toJson() => {
        'ok': ok,
      };
}
