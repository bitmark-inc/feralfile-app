import 'package:autonomy_flutter/util/passkey_utils.dart';
import 'package:passkeys/types.dart';

// Main model class for CredentialRequestOption
class CredentialRequestOption {
  final PublicKeyCredentialRequestOptions publicKey;
  final MediationType? mediation;

  CredentialRequestOption({
    required this.publicKey,
    this.mediation,
  });

  factory CredentialRequestOption.fromJson(Map<String, dynamic> json) =>
      CredentialRequestOption(
        publicKey:
            PublicKeyCredentialRequestOptions.fromJson(json['publicKey']),
        mediation: json['mediation'] == null
            ? null
            : getMediationTypeFromString(json['mediation']),
      );
}

// Model for CredProps (within ClientExtensionResults)
class CredProps {
  final bool? rk;

  CredProps({this.rk});

  factory CredProps.fromJson(Map<String, dynamic> json) =>
      CredProps(rk: json['rk']);
}

// Model for Extensions (appid, appidExclude, and credProps)
class CredentialExtensions {
  final bool? appid;
  final bool? appidExclude;
  final CredProps? credProps;

  CredentialExtensions({
    this.appid,
    this.appidExclude,
    this.credProps,
  });

  factory CredentialExtensions.fromJson(Map<String, dynamic> json) =>
      CredentialExtensions(
        appid: json['appid'],
        appidExclude: json['appidExclude'],
        credProps: json['credProps'] != null
            ? CredProps.fromJson(json['credProps'])
            : null,
      );
}

// Model for PublicKeyCredentialRequestOptions
class PublicKeyCredentialRequestOptions {
  final String challenge;
  final int? timeout;
  final String? rpId;
  final List<CredentialType>? allowCredentials;
  final String? userVerification;
  final CredentialExtensions? extensions;

  PublicKeyCredentialRequestOptions({
    required this.challenge,
    this.timeout,
    this.rpId,
    this.allowCredentials,
    this.userVerification,
    this.extensions,
  });

  factory PublicKeyCredentialRequestOptions.fromJson(
          Map<String, dynamic> json) =>
      PublicKeyCredentialRequestOptions(
        challenge: json['challenge'],
        timeout: json['timeout'],
        rpId: json['rpId'],
        allowCredentials: json['allowCredentials'] != null
            ? (json['allowCredentials'] as List)
                .map((cred) => getCredentialTypeFromJsonFF(cred))
                .toList()
            : null,
        userVerification: json['userVerification'],
        extensions: json['extensions'] != null
            ? CredentialExtensions.fromJson(json['extensions'])
            : null,
      );
}

MediationType getMediationTypeFromString(String mediation) {
  switch (mediation.toLowerCase()) {
    case 'silent':
      return MediationType.Silent;
    case 'optional':
      return MediationType.Optional;
    case 'required':
      return MediationType.Required;
    default:
      throw Exception('Unknown mediation type: $mediation');
  }
}
