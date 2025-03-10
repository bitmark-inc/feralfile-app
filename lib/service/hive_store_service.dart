import 'dart:async';

import 'package:autonomy_flutter/util/log.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract class HiveStoreObjectService<T> {
  Future<void> init(String key);

  Future<void> save(T obj, String objId);

  Future<void> delete(String objId);

  T? get(String objId);

  List<T> getAll();

  Future<void> clear();
}

class HiveStoreObjectServiceImpl<T> implements HiveStoreObjectService<T> {
  late Box<T> _box;

  @override
  Future<void> init(String key) async {
    _box = await Hive.openBox<T>(key);
  }

  @override
  Future<void> delete(String objId) => _box.delete(objId);

  @override
  T? get(String objId) {
    try {
      return _box.get(objId);
    } catch (e) {
      log.info('Hive error getting object from Hive: $e');
      return null;
    }
  }

  @override
  List<T> getAll() => _box.values.toList();

  @override
  Future<void> save(T obj, String objId) async {
    try {
      await _box.put(objId, obj);
    } catch (e) {
      // log.info('Hive error saving object to Hive: $e');
    }
  }

  @override
  Future<void> clear() async {
    await _box.clear();
    log.info('Hive cleared ${_box.name}');
  }
}
