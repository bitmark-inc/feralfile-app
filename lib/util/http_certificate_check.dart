import 'dart:async';
import 'dart:io';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/util/bytes_utils.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:sentry/sentry.dart';

Future<String?> _fetchCertificate(Uri url) async {
  String? hexString;
  // Create an HttpClient to make a request and get the certificate
  final client = HttpClient();
  try {
    final request = await client.headUrl(url);
    final response = await request.close();

    // Extract the certificate
    final certificate = response.certificate;

    if (certificate != null) {
      log.info('Certificate sha1: ${certificate.sha1}');
      hexString = certificate.sha1.toHexString();
      log.info('Certificate sha1 hex: $hexString');
    }
  } catch (e) {
    log.info('Error while get certificate: $e');
  } finally {
    log.info('Certificate check done $hexString');
    // Close the HttpClient
    client.close();
  }
  return hexString;
}

Future<bool> checkCertificate(String url) async {
  if (url.startsWith('http://localhost:') ||
      url.startsWith('http://192.168.')) {
    log.info('Localhost, skip certificate check');
    return true;
  }

  final fingerprint = await _fetchCertificate(Uri.parse(url));
  if (fingerprint == null) {
    unawaited(Sentry.captureMessage(
      'No certificate found',
      params: [
        {'url': url}
      ],
    ));
    return false;
  }

  final configs = injector<RemoteConfigService>();
  final allowedFingerprints = configs.getConfig<List<dynamic>>(
    ConfigGroup.inAppWebView,
    ConfigKey.allowedFingerprints,
    [],
  );
  log.info('Allowed fingerprints: $allowedFingerprints');
  final result = allowedFingerprints.contains(fingerprint);
  log.info('Certificate check result: $result');
  if (!result) {
    unawaited(Sentry.captureMessage(
      'Certificate check failed',
      params: [
        {'url': url, 'fingerprint': fingerprint}
      ],
    ));
  }
  return result;
}
