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
}