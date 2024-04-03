// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

// Example function for encryption
Future<List<dynamic>> _encryptText(String text, String key) async {
  final algorithm = Chacha20.poly1305Aead();
  final bytes = utf8.encode(key);
  final secretKey = await algorithm.newSecretKeyFromBytes(bytes);
  final secretBox = await algorithm.encryptString(text, secretKey: secretKey);
  final encryptText = secretBox.concatenation();
  return [
    base64Encode(encryptText),
    secretBox.nonce.length,
    secretBox.mac.bytes.length
  ];
}

String _generateKeyFromEntropy(String entropy, int length) {
  final random = Random(entropy.hashCode); // Use entropy's hash code as seed
  final entropyLength = entropy.length;
  return String.fromCharCodes(Iterable.generate(
      length, (_) => entropy.codeUnitAt(random.nextInt(entropyLength))));
}

void main(List<String> arguments) async {
  if (arguments.length < 2) {
    print('Usage: dart encrypt.dart <text_to_encrypt> <entropy>');
    return;
  }

  String textToEncrypt = arguments[0];
  String entropy = arguments[1];

  final encryptedText =
      await _encryptText(textToEncrypt, _generateKeyFromEntropy(entropy, 32));
  print(encryptedText.join(' '));
}
