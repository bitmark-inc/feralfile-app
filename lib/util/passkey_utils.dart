import 'package:passkeys/types.dart';

extension RegisterResponseTypeExt on RegisterResponseType {
  Map<String, dynamic> toCredentialCreationResponseJson() => {
        'id': id,
        'rawId': rawId,
        'type': 'public-key',
        'response': {
          'clientDataJSON': clientDataJSON,
          'attestationObject': attestationObject,
        }
      };
}
