import 'package:autonomy_flutter/util/passkey_utils.dart';
import 'package:passkeys/types.dart';

class CredentialCreationOptionResponse {
  final CredentialCreationOption credentialCreationOption;
  final String passkeyUserID;

  CredentialCreationOptionResponse({
    required this.credentialCreationOption,
    required this.passkeyUserID,
  });

  factory CredentialCreationOptionResponse.fromJson(
          Map<String, dynamic> json) =>
      CredentialCreationOptionResponse(
        credentialCreationOption: CredentialCreationOption.fromJson(
            json['credentialCreation'] as Map<String, dynamic>),
        passkeyUserID: json['passkeyUserID'] as String,
      );
}

class CredentialCreationOption {
  final PublicKey publicKey;

  CredentialCreationOption({
    required this.publicKey,
  });

  factory CredentialCreationOption.fromJson(Map<String, dynamic> json) =>
      CredentialCreationOption(
        publicKey:
            PublicKey.fromJson(json['publicKey'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'publicKey': publicKey.toJson(),
      };
}

// Main model class for CredentialCreationOption
class PublicKey {
  final RelyingPartyType rp;
  final UserType user;
  final String challenge;
  final List<PubKeyCredParamType> pubKeyCredParams;
  final int? timeout;
  final List<CredentialType>? excludeCredentials;
  final AuthenticatorSelectionType? authenticatorSelection;
  final String? attestation;
  final Map<String, dynamic>? extensions;

  PublicKey({
    required this.rp,
    required this.user,
    required this.challenge,
    required this.pubKeyCredParams,
    this.timeout,
    this.excludeCredentials,
    this.authenticatorSelection,
    this.attestation,
    this.extensions,
  });

  factory PublicKey.fromJson(Map<String, dynamic> json) => PublicKey(
        rp: RelyingPartyType.fromJson(json['rp'] as Map<String, dynamic>),
        user: UserType.fromJson(json['user'] as Map<String, dynamic>),
        challenge: json['challenge'] as String,
        pubKeyCredParams: (json['pubKeyCredParams'] as List)
            .map((param) =>
                PubKeyCredParamType.fromJson(param as Map<String, dynamic>))
            .toList(),
        timeout: json['timeout'] as int?,
        excludeCredentials: json['excludeCredentials'] != null
            ? (json['excludeCredentials'] as List)
                .map((cred) =>
                    getCredentialTypeFromJsonFF(cred as Map<String, dynamic>))
                .toList()
            : null,
        authenticatorSelection: json['authenticatorSelection'] != null
            ? AuthenticatorSelectionType.fromJson(
                json['authenticatorSelection'] as Map<String, dynamic>)
            : null,
        attestation: json['attestation'] as String?,
        extensions: json['extensions'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'rp': rp.toJson(),
        'user': user.toJson(),
        'challenge': challenge,
        'pubKeyCredParams':
            pubKeyCredParams.map((param) => param.toJson()).toList(),
        'timeout': timeout,
        'excludeCredentials':
            excludeCredentials?.map((cred) => cred.toJson()).toList(),
        'authenticatorSelection': authenticatorSelection?.toJson(),
        'attestation': attestation,
        'extensions': extensions,
      };
}

// Model for authentication-selection-entity (AuthenticatorSelectionCriteria)
class AuthenticatorSelectionEntity {
  final String? authenticatorAttachment;
  final bool? requireResidentKey;
  final String? userVerification;

  AuthenticatorSelectionEntity({
    this.authenticatorAttachment,
    this.requireResidentKey,
    this.userVerification,
  });

  factory AuthenticatorSelectionEntity.fromJson(Map<String, dynamic> json) =>
      AuthenticatorSelectionEntity(
        authenticatorAttachment: json['authenticatorAttachment'] as String?,
        requireResidentKey: json['requireResidentKey'] as bool?,
        userVerification: json['userVerification'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'authenticatorAttachment': authenticatorAttachment,
        'requireResidentKey': requireResidentKey,
        'userVerification': userVerification,
      };
}
