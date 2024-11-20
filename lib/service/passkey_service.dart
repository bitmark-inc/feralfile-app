import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/gateway/user_api.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/passkey_utils.dart';
import 'package:autonomy_flutter/util/user_account_channel.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

abstract class PasskeyService {
  Future<bool> doesOSSupport();

  Future<bool> canAuthenticate();

  Future<AuthenticateResponseType> logInInitiate();

  Future<JWT> logInFinalize(AuthenticateResponseType authenticateResponse);

  Future<void> registerInitiate();

  Future<JWT> registerFinalize();

  Future<JWT> requestJwt();

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
  Future<bool> doesOSSupport() async {
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
  Future<bool> canAuthenticate() async => true;

  //await _passkeyAuthenticator.canAuthenticate();

  @override
  Future<AuthenticateResponseType> logInInitiate() async {
    try {
      log.info('Login initiate');
      final loginRequest = await _logInSeverInitiate();
      log.info('Login initiate done, login request: $loginRequest');
      return await _authenticate(loginRequest);
    } catch (e, s) {
      log.info('Failed to login initiate: $e');
      unawaited(Sentry.captureException(e, stackTrace: s));
      rethrow;
    }
  }

  Future<AuthenticateResponseType> _authenticate(
      AuthenticateRequestType loginRequest) async {
    log.info('Authenticate, show login dialog');
    try {
      _isShowingLoginDialog.value = true;
      final response = await _passkeyAuthenticator.authenticate(loginRequest);
      _isShowingLoginDialog.value = false;
      log.info('Authenticate done, return response: $response');
      return response;
    } catch (e, s) {
      log.info('Failed to authenticate: $e');
      unawaited(Sentry.captureException(e, stackTrace: s));
      rethrow;
    }
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
  Future<JWT> logInFinalize(
      AuthenticateResponseType authenticateResponse) async {
    try {
      log.info('Login finalize');
      final jwt = await _userApi.logInFinalize(authenticateResponse.toFFJson());
      log.info('Login finalize done, set auth token');
      await _authService.setAuthToken(jwt);
      log.info('Login finalize done');
      return jwt;
    } catch (e, s) {
      log.info('Failed to login finalize: $e');
      unawaited(Sentry.captureException(e, stackTrace: s));
      rethrow;
    }
  }

  @override
  Future<void> registerInitiate() async {
    try {
      log.info('Register initiate');
      final registerRequest = await _initializeServerRegistration();
      _registerResponse = await _passkeyAuthenticator.register(registerRequest);
      log.info('Register initiate done, register response: $_registerResponse');
    } catch (e) {
      log.info('Failed to register initiate: $e');
      unawaited(Sentry.captureException(e));
      rethrow;
    }
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
  Future<JWT> registerFinalize() async {
    if (_registerResponse == null || _passkeyUserId == null) {
      throw Exception('Initialize registration has not finished');
    }
    final addressAuthentication =
        await _addressService.getAddressAuthenticationMap();
    final jwt = await _userApi.registerFinalize({
      'addressAuthentication': addressAuthentication,
      'passkeyUserId': _passkeyUserId,
      'credentialCreationResponse':
          _registerResponse!.toCredentialCreationResponseJson(),
    });
    await _userAccountChannel.setDidRegisterPasskey(true);
    await _authService.setAuthToken(jwt);
    return jwt;
  }

  @override
  Future<JWT> requestJwt() async {
    final localResponse = await logInInitiate();
    final jwt = await logInFinalize(localResponse);
    return jwt;
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
