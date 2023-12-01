import 'dart:async';

Map<String, bool> _blocking = {};

void withDebounce(Function() func,
    {String key = 'click', int debounceTime = 500}) {
  if (_blocking[key] == true) {
    return;
  }

  _blocking[key] = true;
  func.call();

  Timer(Duration(microseconds: debounceTime), () {
    _blocking.remove(key);
  });
}
