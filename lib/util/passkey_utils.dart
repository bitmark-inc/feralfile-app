import 'package:autonomy_flutter/service/passkey_service.dart';
import 'package:passkeys/types.dart';

extension RegisterResponseTypeExt on RegisterResponseType {
  Map<String, dynamic> toCredentialCreationResponseJson() => {
        'id': id,
        'rawId': rawId,
        'type': PasskeyService.authenticationType,
        'response': {
          'clientDataJSON': clientDataJSON,
          'attestationObject': attestationObject,
        }
      };
}

extension AuthenticateResponseTypeExt on AuthenticateResponseType {
  Map<String, dynamic> toFFJson() => {
        'id': id,
        'rawId': rawId,
        'type': PasskeyService.authenticationType,
        'response': {
          'clientDataJSON': clientDataJSON,
          'authenticatorData': authenticatorData,
          'signature': signature,
          'userHandle': userHandle,
        }
      };
}

CredentialType getCredentialTypeFromJsonFF(Map<String, dynamic> json) =>
    CredentialType(
      type: json['type'] as String,
      id: json['id'] as String,
      transports: json['transports'] == null
          ? []
          : (json['transports'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
    );
