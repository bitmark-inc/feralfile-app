import 'dart:io';

import 'package:autonomy_flutter/gateway/user_api.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/util/passkey_utils.dart';
import 'package:autonomy_flutter/util/user_account_channel.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

abstract class PasskeyService {
  Future<bool> isPassKeyAvailable();

  Future<AuthenticateResponseType> logInInitiate();

  Future<void> logInFinalize(AuthenticateResponseType authenticateResponse);

  Future<void> registerInitiate();

  Future<void> registerFinalize();

  ValueNotifier<bool> get isShowingLoginDialog;

  static String authenticationType = 'public-key';
}

class PasskeyServiceImpl implements PasskeyService {
  final _passkeyAuthenticator = PasskeyAuthenticator();

  RegisterResponseType? _registerResponse;
  String? _passkeyUserId;

  final UserApi _userApi;
  final UserAccountChannel _userAccountChannel;
  final AddressService _addressService;
  final AuthService _authService;

  PasskeyServiceImpl(
    this._userApi,
    this._userAccountChannel,
    this._addressService,
    this._authService,
  );

  final ValueNotifier<bool> _isShowingLoginDialog = ValueNotifier(false);

  static const _defaultMediation = MediationType.Optional;

  static const _preferImmediatelyAvailableCredentials = false;

  @override
  ValueNotifier<bool> get isShowingLoginDialog => _isShowingLoginDialog;

  @override
  Future<bool> isPassKeyAvailable() async =>
      await _passkeyAuthenticator.canAuthenticate() && await _doesOSSupport();

  Future<bool> _doesOSSupport() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      // Android 9 (API 28) and above
      return androidInfo.version.sdkInt >= 28;
    } else {
      final iosInfo = await deviceInfo.iosInfo;
      // iOS 16 and above
      final osVersion = iosInfo.systemVersion.split('.').first;
      return (int.tryParse(osVersion) ?? 0) >= 16;
    }
  }

  @override
  Future<AuthenticateResponseType> logInInitiate() async {
    final loginRequest = await _logInSeverInitiate();
    return await _authenticate(loginRequest);
  }

  Future<AuthenticateResponseType> _authenticate(
      AuthenticateRequestType loginRequest) async {
    _isShowingLoginDialog.value = true;
    final response = await _passkeyAuthenticator.authenticate(loginRequest);
    _isShowingLoginDialog.value = false;
    return response;
  }

  Future<AuthenticateRequestType> _logInSeverInitiate() async {
    // userId is the address that sign the message when register,
    // which is the primary address
    final userId = await _addressService.getPrimaryAddress();
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
      mediation: response.mediation ?? _defaultMediation,
      preferImmediatelyAvailableCredentials:
          _preferImmediatelyAvailableCredentials,
      timeout: pubKey.timeout,
      userVerification: pubKey.userVerification,
    );
  }

  @override
  Future<void> logInFinalize(
      AuthenticateResponseType authenticateResponse) async {
    final response =
        await _userApi.logInFinalize(authenticateResponse.toFFJson());
    _authService.setAuthToken(response);
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
      attestation: pubKey.attestation,
      timeout: pubKey.timeout,
      pubKeyCredParams: pubKey.pubKeyCredParams,
    );
  }

  @override
  Future<void> registerFinalize() async {
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
    _authService.setAuthToken(response);
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
