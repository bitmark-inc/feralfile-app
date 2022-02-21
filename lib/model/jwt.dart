class JWT {
  int? expireIn;
  String jwtToken;
  DateTime _createdAt = DateTime.now();

  JWT({required this.jwtToken, this.expireIn});

  JWT.fromJson(Map<String, dynamic> json)
      : expireIn = json['expire_in'],
        jwtToken = json['jwt_token'];

  Map<String, dynamic> toJson() => {
        'expire_in': expireIn,
        'jwt_token': jwtToken,
      };

  bool isValid() {
    if (expireIn != null) {
      final duration = Duration(minutes: expireIn! - 5);
      final value = _createdAt.add(duration).compareTo(DateTime.now());
      return value > 0;
    }

    return true;
  }
}
