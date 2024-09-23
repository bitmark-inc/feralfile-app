extension IterableExtension<E> on Iterable<E> {
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
}
