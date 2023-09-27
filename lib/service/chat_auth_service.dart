import 'package:autonomy_flutter/gateway/chat_api.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/util/jwt.dart';

class ChatAuthService {
  final ChatApi _chatApi;

  ChatAuthService(this._chatApi);

  final Map<String, JWT> _jwts = {};
  static const int _expireBuffer = 10000;

  bool _isExpire(String address) {
    final jwt = _jwts[address];
    if (jwt == null) {
      return true;
    }
    final exp = jwt.expireIn ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now > exp + _expireBuffer;
  }

  Future<String> getAuthToken(Map<String, dynamic> body,
      {required String address}) async {
    if (!_isExpire(address)) {
      return _jwts[address]!.jwtToken;
    }
    final token = await _chatApi.getToken(body);
    final exp = parseJwt(token.token)['exp'] as int;
    _jwts[address] = JWT(jwtToken: token.token, expireIn: exp * 1000);
    return token.token;
  }
}
