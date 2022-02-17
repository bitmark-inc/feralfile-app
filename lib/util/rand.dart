import 'dart:math';

var random = Random.secure();

String generateRandomString(int len) {
  const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  return List.generate(len, (index) => _chars[random.nextInt(_chars.length)])
      .join();
}

String generateRandomHex(int len) {
  return List<String>.generate(
      len, (i) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}
