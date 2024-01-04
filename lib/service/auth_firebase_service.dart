import 'dart:convert';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:libauk_dart/libauk_dart.dart';

class AuthFiresabeService {
  static User? _user;

  // init service
  Future<void> initService() async {
    addAuthChangeListener();
  }

  IAPApi get _iapApi => injector.get<IAPApi>();

  bool get isSignedIn => _user != null && _user!.uid.isNotEmpty;

  Future<String> getJWTToken(Persona persona) async {
    final authService = injector.get<AuthService>();
    final accountService = injector.get<AccountService>();
    final endpoint = Environment.autonomyAuthURL;
    final account = await persona.wallet();
    final authToken = await getAuthToken(account);

    final response = await http
        .get(Uri.parse('$endpoint/apis/v1/me/jwts/firebase'), headers: {
      'Authorization': 'Bearer $authToken',
      "Content-Type": "application/json"
    });
    final bodyBytes = response.bodyBytes;
    final bodyJson = json.decode(utf8.decode(bodyBytes));
    return bodyJson['jwt'];
  }

  Future<String> getAuthToken(WalletStorage account) async {
    final message = DateTime.now().millisecondsSinceEpoch.toString();
    final accountDID = await account.getAccountDID();
    final signature = await account.getAccountDIDSignature(message);

    Map<String, dynamic> payload = {
      'requester': accountDID,
      'timestamp': message,
      'signature': signature,
    };

    final jwt = await _iapApi.auth(payload);
    return jwt.jwtToken;
  }

  static void addAuthChangeListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _user = user;
      } else {
        _user = null;
      }
    });
  }

  User? get user => _user;

  Future<User?> signInWithPersona(Persona persona) async {
    final auth = FirebaseAuth.instance;
    final jwt = await getJWTToken(persona);
    final userCredential = await auth.signInWithCustomToken(jwt);
    _user = userCredential.user;
    return user;
  }

  Future<void> signOut() async {
    final auth = FirebaseAuth.instance;
    await auth.signOut();
    _user = null;
  }
}
