import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/user_api.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/passkey_utils.dart';
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
  PasskeyServiceImpl(
    this._userApi,
    this._authService,
  );

  final _passkeyAuthenticator = PasskeyAuthenticator();

  RegisterResponseType? _registerResponse;
  String? _passkeyUserId;

  final UserApi _userApi;
  final AuthService _authService;

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
  Future<bool> canAuthenticate() async =>
      Platform.isAndroid ? await _passkeyAuthenticator.canAuthenticate() : true;

  // passkey available always return true for iOS
  // if no verification method is available,
  // the user will be prompted to set up passcode or faceID

  @override
  Future<AuthenticateResponseType> logInInitiate() async {
    try {
      log.info('Login initiate');
      final loginRequest = await _logInSeverInitiate();
      log.info('Login initiate done, login request: $loginRequest');
      final res = await _authenticate(loginRequest);
      return res;
    } catch (e, s) {
      log.info('Failed to login initiate: $e');
      unawaited(Sentry.captureException(e, stackTrace: s));
      rethrow;
    }
  }

  Future<AuthenticateResponseType> _authenticate(
    AuthenticateRequestType loginRequest,
  ) async {
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
    final userId = injector<AuthService>().getUserId();
    final response = userId != null
        ? await _userApi.logInInitializeWithUserId(userId)
        : await _userApi.logInInitialize();
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
    AuthenticateResponseType authenticateResponse,
  ) async {
    try {
      log.info('Login finalize');
      final response =
          await _userApi.logInFinalize(authenticateResponse.toFFJson());
      log.info('Login finalize done, set auth token');
      await _authService.setAuthToken(response);
      log.info('Login finalize done');
      return response;
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
    final response = await _userApi.registerFinalize({
      'passkeyUserId': _passkeyUserId,
      'credentialCreationResponse':
          _registerResponse!.toCredentialCreationResponseJson(),
    });
    await _authService.setAuthToken(response);
    return response;
  }

  @override
  Future<JWT> requestJwt() async {
    log.info('[PasskeyService] Request JWT');
    final localResponse = await logInInitiate();
    log.info('[PasskeyService] Log in initiated');
    final jwt = await logInFinalize(localResponse);
    log
      ..info('[PasskeyService] Log in finalized')
      ..info('[PasskeyService] return JWT done');
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
