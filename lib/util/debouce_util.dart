import 'dart:async';

Map<String, bool> _blocking = {};

void withDebounce(FutureOr<dynamic> Function() func,
    {String key = 'click', int debounceTime = 500}) {
  if (_blocking[key] == true) {
    return;
  }

  _blocking[key] = true;
  try {
    // ignore: unawaited_futures
    final res = func.call();
    if (res is Future) {
      unawaited(res.whenComplete(() {
        Timer(Duration(microseconds: debounceTime), () {
          _blocking.remove(key);
        });
      }));
    } else {
      Timer(Duration(microseconds: debounceTime), () {
        _blocking.remove(key);
      });
    }
  } catch (e) {
    Timer(Duration(microseconds: debounceTime), () {
      _blocking.remove(key);
    });
  }
}
