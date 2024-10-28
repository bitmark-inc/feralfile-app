import 'package:autonomy_flutter/gateway/user_api.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/util/passkey_utils.dart';
import 'package:autonomy_flutter/util/user_account_channel.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

abstract class PasskeyService {
  Future<bool> isPassKeyAvailable();

  Future<AuthenticateResponseType> logInInitiate();

  Future<JWT> logInFinalize(AuthenticateResponseType loginResponse);

  Future<void> registerInitiate();

  Future<JWT> registerFinalize();
}

class PasskeyServiceImpl implements PasskeyService {
  final _passkeyAuthenticator = PasskeyAuthenticator();

  RegisterResponseType? _registerResponse;
  String? _passkeyUserId;

  final UserApi _userApi;
  final UserAccountChannel _userAccountChannel;
  final AddressService _addressService;

  PasskeyServiceImpl(
    this._userApi,
    this._userAccountChannel,
    this._addressService,
  );

  /*
  static final AuthenticatorSelectionType _defaultAuthenticatorSelection =
      AuthenticatorSelectionType(
    requireResidentKey: false,
    residentKey: 'discouraged',
    userVerification: 'preferred',
  );

  static const _defaultRelayingPartyId = 'accounts.dev.feralfile.com';

 */

  static const _preferImmediatelyAvailableCredentials = false;

  @override
  Future<bool> isPassKeyAvailable() async =>
      await _passkeyAuthenticator.canAuthenticate();

  @override
  Future<AuthenticateResponseType> logInInitiate() async {
    final loginRequest = await _logInSeverInitiate();
    return await _passkeyAuthenticator.authenticate(loginRequest);
  }

  Future<AuthenticateRequestType> _logInSeverInitiate() async {
    final userId = await _userAccountChannel.getUserId();
    if (userId == null) {
      throw Exception('User ID is not set');
    }
    final response = await _userApi.logInInitialize(userId);
    final pubKey = response.publicKey;

    if (pubKey.rpId == null) {
      throw Exception('RP ID is not set');
    }
    return AuthenticateRequestType(
      challenge: pubKey.challenge,
      allowCredentials: pubKey.allowCredentials ?? [],
      relyingPartyId: pubKey.rpId!,
      mediation: response.mediation,
      preferImmediatelyAvailableCredentials:
          _preferImmediatelyAvailableCredentials,
    );
  }

  @override
  Future<JWT> logInFinalize(AuthenticateResponseType loginLocalResponse) async {
    final response = await _userApi.logInFinalize({
      'public_key_credential': loginLocalResponse.toJson(),
    });
    return response;
  }

  @override
  Future<void> registerInitiate() async {
    final registerRequest = await _initializeServerRegistration();
    _registerResponse = await _passkeyAuthenticator.register(registerRequest);
  }

  Future<RegisterRequestType> _initializeServerRegistration() async {
    final response = await _userApi.registerInitialize();
    final pubKey = response.credentialCreationOption.publicKey;
    if (pubKey.authenticatorSelection == null) {
      throw Exception('Authenticator selection is not set');
    }
    _passkeyUserId = response.passkeyUserID;
    return RegisterRequestType(
      challenge: pubKey.challenge,
      relyingParty: pubKey.rp,
      user: pubKey.user,
      authSelectionType: pubKey.authenticatorSelection!,
      excludeCredentials: pubKey.excludeCredentials ?? [],
    );
  }

  @override
  Future<JWT> registerFinalize() async {
    if (_registerResponse == null || _passkeyUserId == null) {
      throw Exception('Initialize registration has not finished');
    }
    final addressAuthentication =
        await _addressService.getAddressAuthenticationMap();
    final response = await _userApi.registerFinalize({
      'addressAuthentication': addressAuthentication,
      'passkeyUserId': _passkeyUserId,
      'credentialCreationResponse':
          _registerResponse!.toCredentialCreationResponseJson(),
    });
    await _userAccountChannel.setDidRegisterPasskey(true);
    await _userAccountChannel.setUserId(addressAuthentication['requester']);
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
