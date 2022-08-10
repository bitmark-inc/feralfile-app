//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: depend_on_referenced_packages, implementation_imports

import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_cache_manager/src/storage/cache_info_repositories/cache_info_repository.dart';
import 'package:flutter_cache_manager/src/storage/cache_info_repositories/helper_methods.dart';
import 'package:flutter_cache_manager/src/storage/cache_object.dart';
import 'package:hive/hive.dart';

class AUCacheInfoRepository extends CacheInfoRepository
    with CacheInfoRepositoryHelperMethods {
  String? name;

  /// Either the path or the database name should be provided.
  /// If the path is provider it should end with '{databaseName}.json',
  /// for example: /data/user/0/com.example.example/databases/imageCache.json
  AUCacheInfoRepository({this.name});

  /// The directory and the databaseName should both the provided. The database
  /// is stored as {databaseName}.json in the directory,
  // AUCacheInfoRepository.withFile(File file) : _file = file;

  final Map<int, Map<String, dynamic>> _auCache = {};

  late Box<Map> _box;
  static const String defaultBoxName = 'au_image_cache';

  @override
  Future<bool> open() async {
    if (!shouldOpenOnNewConnection()) {
      return openCompleter!.future;
    }

    _box = await Hive.openBox(name ?? defaultBoxName);
    return true;
  }

  @override
  Future<CacheObject?> get(String key) async {
    final value = _box.get(key);
    return value != null
        ? CacheObject.fromMap(value.cast<String, dynamic>())
        : null;
  }

  @override
  Future<List<CacheObject>> getAllObjects() async {
    return _box.values
        .map((e) => CacheObject.fromMap(e.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<CacheObject> insert(
    CacheObject cacheObject, {
    bool setTouchedToNow = true,
  }) async {
    if (cacheObject.id != null) {
      throw ArgumentError("Inserted objects shouldn't have an existing id.");
    }
    var keys = _auCache.keys;
    var lastId = keys.isEmpty ? 0 : keys.reduce(max);
    var id = lastId + 1;

    cacheObject = cacheObject.copyWith(id: id);
    return _put(cacheObject, setTouchedToNow);
  }

  @override
  Future<int> update(
    CacheObject cacheObject, {
    bool setTouchedToNow = true,
  }) async {
    if (cacheObject.id == null) {
      throw ArgumentError('Updated objects should have an existing id.');
    }
    _put(cacheObject, setTouchedToNow);
    return 1;
  }

  @override
  Future updateOrInsert(CacheObject cacheObject) {
    return cacheObject.id == null ? insert(cacheObject) : update(cacheObject);
  }

  @override
  Future<List<CacheObject>> getObjectsOverCapacity(int capacity) async {
    var allSorted = _box.values
        .map((e) => CacheObject.fromMap(e.cast<String, dynamic>()))
        .toList()
      ..sort((c1, c2) => c1.touched!.compareTo(c2.touched!));
    if (allSorted.length <= capacity) return [];
    return allSorted.getRange(0, allSorted.length - capacity).toList();
  }

  @override
  Future<List<CacheObject>> getOldObjects(Duration maxAge) async {
    var oldestTimestamp = DateTime.now().subtract(maxAge);
    return _box.values
        .map((e) => CacheObject.fromMap(e.cast<String, dynamic>()))
        .where(
          (element) => element.touched!.isBefore(oldestTimestamp),
        )
        .toList();
  }

  @override
  Future<int> delete(int id) async {
    var cacheObject = _box.values
        .map((e) => CacheObject.fromMap(e.cast<String, dynamic>()))
        .firstWhereOrNull(
          (element) => element.id == id,
        );
    if (cacheObject == null) {
      return 0;
    }
    _remove(cacheObject);
    return 1;
  }

  @override
  Future<int> deleteAll(Iterable<int> ids) async {
    var deleted = 0;
    for (var id in ids) {
      deleted += await delete(id);
    }
    return deleted;
  }

  @override
  Future<bool> close() async {
    if (!shouldClose()) {
      return false;
    }
    await _saveFile();
    return true;
  }

  CacheObject _put(CacheObject cacheObject, bool setTouchedToNow) {
    final map = cacheObject.toMap(setTouchedToNow: setTouchedToNow);
    _auCache[cacheObject.id!] = map;
    var updatedCacheObject = CacheObject.fromMap(map);
    _box.put(cacheObject.key, cacheObject.toMap());
    _cacheUpdated();
    return updatedCacheObject;
  }

  void _remove(CacheObject cacheObject) {
    _box.delete(cacheObject.key);
    _auCache.remove(cacheObject.id);
    _cacheUpdated();
  }

  void _cacheUpdated() {
    EasyDebounce.debounce('saveFile', const Duration(seconds: 3), _saveFile);
  }

  Future _saveFile() async {
    await _box.flush();
  }

  @override
  Future deleteDataFile() async {
    return await _box.deleteFromDisk();
  }

  @override
  Future<bool> exists() {
    return Hive.boxExists(name ?? defaultBoxName);
  }
}
