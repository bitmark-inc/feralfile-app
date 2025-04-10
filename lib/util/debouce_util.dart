import 'dart:async';

Map<String, bool> _blocking = {};

FutureOr<T> withDebounce<T>(FutureOr<T> Function() func,
    {String? key, int debounceTime = 500}) {
  // generate a unique key if not provided
  key ??= DateTime.now().millisecondsSinceEpoch.toString();
  if (_blocking[key] == true) {
    throw StateError('Debounced action is blocked for key: $key');
  }

  _blocking[key] = true;

  Future<void> clearBlocking() async {
    await Future.delayed(Duration(milliseconds: debounceTime));
    _blocking.remove(key);
  }

  try {
    final result = func.call();

    if (result is Future<T>) {
      return result.whenComplete(clearBlocking);
    } else {
      clearBlocking();
      return result;
    }
  } catch (e) {
    clearBlocking();
    rethrow; // Re-throw the error for the caller to handle
  }
}
