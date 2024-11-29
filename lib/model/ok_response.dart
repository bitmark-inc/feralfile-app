class OkResponse {
  OkResponse({required this.ok});

  factory OkResponse.fromJson(Map<String, dynamic> map) => OkResponse(
        ok: map['ok'] as int,
      );
  final int ok;

  Map<String, dynamic> toJson() => {
        'ok': ok,
      };
}
