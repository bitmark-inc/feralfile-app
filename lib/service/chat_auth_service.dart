import 'package:autonomy_flutter/gateway/chat_api.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/util/jwt.dart';

class ChatAuthService {
  final ChatApi _chatApi;

  ChatAuthService(this._chatApi);

  JWT? _jwt;
  static const int _expireBuffer = 10000;

  bool _isExpire() {
    if (_jwt == null) {
      return true;
    }
    final exp = _jwt!.expireIn ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now > exp + _expireBuffer;
  }

  Future<String> getAuthToken(Map<String, dynamic> body) async {
    if (!_isExpire()) {
      return _jwt!.jwtToken;
    }
    final token = await _chatApi.getToken(body);
    final exp = parseJwt(token.token)['exp'] as int;
    _jwt = JWT(jwtToken: token.token, expireIn: exp * 1000);
    return token.token;
  }
}
