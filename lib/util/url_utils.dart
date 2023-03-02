import 'log.dart';

bool checkHref(String href) {
  try {
    Uri.parse(href);
  } catch (_) {
    log.info("Check href fail: $href");
    return false;
  }
  return true;
}