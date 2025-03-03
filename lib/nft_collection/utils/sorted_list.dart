import 'dart:async';

abstract class AuList<T> {
  late List<T> _list;

  List<T> get items => List.unmodifiable(_list);

  int get length => _list.length;

  bool get isNotEmpty => _list.isNotEmpty;

  bool get isEmpty => _list.isEmpty;

  T get first => _list.first;

  T get last => _list.last;

  T operator [](int index) => _list[index];

  void operator []=(int index, T value) {
    _list[index] = value;
  }

  void remove(T item) {
    _list.remove(item);
  }

  void addAll(List<T> items);

  void insert(T item);

  void removeWhere(bool Function(T) test) {
    _list.removeWhere(test);
  }

  void clear() {
    _list.clear();
  }

  AuList<T> toList();

  AuList<T> unique([
    FutureOr<void> Function(T element)? id,
    bool inplace = true,
  ]);
}

class SortedList<T extends Comparable<T>> extends AuList<T> {
  SortedList([List<T>? value]) {
    _list = value ?? <T>[];
  }

  @override
  void insert(T item) {
    var i = 0;
    while (i < _list.length && item.compareTo(_list[i]) > 0) {
      i++;
    }
    _list.insert(i, item);
  }

  @override
  void addAll(List<T> items) {
    for (final item in items) {
      insert(item);
    }
  }

  @override
  SortedList<T> unique([
    FutureOr<void> Function(T element)? id,
    bool inplace = true,
  ]) {
    final ids = <dynamic>{};
    final list = inplace ? _list : List<T>.from(_list)
      ..retainWhere((x) => ids.add(id != null ? id(x) : x));
    return SortedList<T>(list);
  }

  @override
  SortedList<T> toList() {
    return SortedList<T>(List<T>.from(_list));
  }
}

class NormalList<T> extends AuList<T> {
  NormalList([List<T>? value]) {
    _list = value ?? <T>[];
  }

  @override
  void insert(T item) {
    _list.insert(0, item);
  }

  @override
  void addAll(List<T> items) {
    _list.addAll(items);
  }

  @override
  NormalList<T> unique([
    FutureOr<void> Function(T element)? id,
    bool inplace = true,
  ]) {
    final ids = <dynamic>{};
    final list = inplace ? _list : List<T>.from(_list)
      ..retainWhere((x) => ids.add(id != null ? id(x) : x));
    return NormalList<T>(list);
  }

  @override
  NormalList<T> toList() {
    return NormalList<T>(List<T>.from(_list));
  }
}
