import 'package:autonomy_flutter/util/jwt.dart';

class JWT {
  int? expireIn;
  String jwtToken;

  JWT({required this.jwtToken, this.expireIn});

  JWT.fromJson(Map<String, dynamic> json)
      : expireIn = json['expire_in'],
        jwtToken = json['jwt_token'];

  Map<String, dynamic> toJson() => {
        'expire_in': expireIn,
        'jwt_token': jwtToken,
      };

  bool isValid({bool withSubscription = false}) {
    final claim = parseJwt(jwtToken);
    final exp = (claim['exp'] ?? 0) as int;
    final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    final value = expDate.compareTo(DateTime.now());

    if (withSubscription) {
      final plan = claim['plan'] as String;
      return value > 0 && plan == "autonomy-premium";
    }

    return value > 0;
  }
}

class OnesignalIdentityHash {
  String hash;

  OnesignalIdentityHash({required this.hash});

  OnesignalIdentityHash.fromJson(Map<String, dynamic> json)
      : hash = json['hash'];

  Map<String, dynamic> toJson() => {
        'hash': hash,
      };
}
