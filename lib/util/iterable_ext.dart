// ignore_for_file: type_annotate_public_apis

extension IterableExtension<E> on Iterable<E> {
  Iterable<E> distinctBy<K extends Comparable<K>>({
    required K Function(E e) keyOf,
  }) {
    final keys = <K>{};
    final result = <E>[];
    for (E element in this) {
      final key = keyOf(element);
      if (!keys.contains(key)) {
        result.add(element);
        keys.add(key);
      }
    }
    return result;
  }

  E? firstOrDefault([bool Function(E element)? func]) {
    if (func == null) {
      final it = iterator;
      if (!it.moveNext()) {
        return null;
      }
      return it.current;
    }

    for (var element in this) {
      if (func(element)) {
        return element;
      }
    }

    return null;
  }

  E? lastOrDefault([bool Function(E element)? func]) {
    if (func == null) {
      if (isNotNullOrEmpty) {
        return last;
      }
      return null;
    }

    late E result;
    var foundMatching = false;
    for (final element in this) {
      if (func(element)) {
        result = element;
        foundMatching = true;
      }
    }

    if (foundMatching) {
      return result;
    }
    return null;
  }

  dynamic foldLeft(val, func) {
    forEach((entry) => val = func(val, entry));
    return val;
  }

  List<E> sortedBy(Comparable Function(E e) key) =>
      toList()..sort((a, b) => key(a).compareTo(key(b)));
}

extension IterableNullExtension<E> on Iterable<E>? {
  bool get isNullOrEmpty => this == null || this?.isEmpty == true;

  bool get isNotNullOrEmpty => !isNullOrEmpty;

  E? firstOrDefault([bool Function(E element)? func]) {
    if (func == null && isNotNullOrEmpty) {
      final Iterator<E> it = this!.iterator;
      if (!it.moveNext()) {
        return null;
      }
      return it.current;
    }

    for (var element in this ?? <E>[]) {
      if (func?.call(element) ?? false) {
        return element;
      }
    }

    return null;
  }

  E? lastOrDefault([bool Function(E element)? func]) {
    if (func == null) {
      if (isNotNullOrEmpty) {
        return this?.last;
      }
      return null;
    }

    late E result;
    var foundMatching = false;
    if (isNotNullOrEmpty) {
      for (final element in this!) {
        if (func(element)) {
          result = element;
          foundMatching = true;
        }
      }
    }

    if (foundMatching) {
      return result;
    }
    return null;
  }

  dynamic foldLeft(val, func) {
    for (var element in this ?? <E>[]) {
      val = func(val, element);
    }

    return val;
  }
}
