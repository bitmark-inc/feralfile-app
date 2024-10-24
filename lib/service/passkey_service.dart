import 'package:autonomy_flutter/gateway/user_api.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/util/user_account_channel.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

abstract class PasskeyService {
  Future<bool> isPassKeyAvailable();

  Future<void> logInInitiate();

  Future<AuthenticateResponseType> logInRequest();

  Future<JWT> logInFinalize();

  Future<void> registerInitiate();

  Future<RegisterResponseType> registerRequest();

  Future<JWT> registerFinalize();
}

class PasskeyServiceImpl implements PasskeyService {
  final _passkeyAuthenticator = PasskeyAuthenticator();

  RegisterRequestType? _registerRequest;
  RegisterResponseType? _registerResponse;

  AuthenticateRequestType? _loginRequest;
  AuthenticateResponseType? _loginResponse;

  final UserApi _userApi;
  final UserAccountChannel _userAccountChannel;

  PasskeyServiceImpl(this._userApi, this._userAccountChannel);

  static final AuthenticatorSelectionType _defaultAuthenticatorSelection =
      AuthenticatorSelectionType(
    requireResidentKey: false,
    residentKey: 'discouraged',
    userVerification: 'preferred',
  );

  static const _defaultRelayingPartyId = 'www.feralfile.com';
  static const _preferImmediatelyAvailableCredentials = true;

  @override
  Future<bool> isPassKeyAvailable() async =>
      await _passkeyAuthenticator.canAuthenticate();

  @override
  Future<void> logInInitiate() async {
    final userId = await _userAccountChannel.getUserId();
    if (userId == null) {
      throw Exception('User ID is not set');
    }
    final response = await _userApi.logInInitialize(userId);
    final pubKey = response.publicKey;
    _loginRequest = AuthenticateRequestType(
      challenge: pubKey.challenge,
      allowCredentials: pubKey.allowCredentials ?? [],
      relyingPartyId: pubKey.rpId ?? _defaultRelayingPartyId,
      mediation: response.mediation,
      preferImmediatelyAvailableCredentials:
          _preferImmediatelyAvailableCredentials,
    );
  }

  @override
  Future<AuthenticateResponseType> logInRequest() async {
    if (_loginResponse != null) {
      return _loginResponse!;
    }
    _loginResponse = await _passkeyAuthenticator.authenticate(_loginRequest!);
    return _loginResponse!;
  }

  @override
  Future<JWT> logInFinalize() async {
    final response = await _userApi.logInFinalize({
      'public_key_credential': _loginResponse!.toJson(),
    });
    return response;
  }

  @override
  Future<void> registerInitiate() async {
    final response = await _userApi.registerInitialize();
    final pubKey = response.publicKey;
    _registerRequest = RegisterRequestType(
      challenge: pubKey.challenge,
      relyingParty: pubKey.rp,
      user: pubKey.user,
      authSelectionType:
          pubKey.authenticatorSelection ?? _defaultAuthenticatorSelection,
      excludeCredentials: pubKey.excludeCredentials ?? [],
    );
  }

  @override
  Future<RegisterResponseType> registerRequest() async {
    if (_registerResponse != null) {
      return _registerResponse!;
    }
    _registerResponse = await _passkeyAuthenticator.register(_registerRequest!);
    return _registerResponse!;
  }

  @override
  Future<JWT> registerFinalize() async {
    final response = await _userApi.registerFinalize({
      'public_key_credential': _registerResponse!.toJson(),
    });
    return response;
  }
}

extension RegisterResponseTypeExt on RegisterResponseType {
  Map<String, dynamic> toJson() => {
        'id': id,
        'rawId': rawId,
        'clientDataJSON': clientDataJSON,
        'attestationObject': attestationObject,
      };
}
