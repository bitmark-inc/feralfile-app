extension Unique<E, Id> on List<E>? {
  List<E>? unique([Id Function(E element)? id, bool inplace = true]) {
    final ids = <dynamic>{};
    final list = inplace
        ? this
        : this != null
            ? List<E>.from(this!)
            : null;
    list?.retainWhere((x) => ids.add(id != null ? id(x) : x as Id));
    return list;
  }
}
