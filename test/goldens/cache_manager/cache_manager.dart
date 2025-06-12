import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/file.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class _InMemoryFile extends File {
  final Uint8List _bytes;

  _InMemoryFile(this._bytes) : super();

  @override
  Future<Uint8List> readAsBytes() async {
    debugPrint('Reading bytes from in-memory file');
    return _bytes;
  }

  // Stub everything else since it's not used
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCacheManage implements CacheManager {
  MockCacheManage();

  Future<FileInfo> _loadMockAssetFileInfo(String keyOrUrl) async {
    debugPrint('Loading mock asset for URL: $keyOrUrl');
    try {
      debugPrint('Successfully loaded asset file');
      final bytes = await rootBundle
          .load('assets/images/2.0x/Android_TV_living_room.png')
          .then((value) => value.buffer.asUint8List());

      final file = _InMemoryFile(bytes);

      return FileInfo(
        file,
        FileSource.Cache,
        DateTime.now().add(const Duration(days: 30)),
        keyOrUrl,
      );
    } catch (e) {
      debugPrint('Error loading mock asset: $e');
      rethrow;
    }
  }

  @override
  Stream<FileResponse> getFileStream(String url,
      {String? key, Map<String, String>? headers, bool? withProgress}) async* {
    debugPrint('Getting file stream for URL: $url');
    yield await _loadMockAssetFileInfo(url);
  }

  @override
  Future<FileInfo?> getFileFromCache(String key,
      {bool ignoreMemCache = false}) async {
    debugPrint('Getting file from cache for key: $key');
    return _loadMockAssetFileInfo(key);
  }

  @override
  Future<FileInfo?> getFileFromMemory(String key) async {
    debugPrint('Getting file from memory for key: $key');
    return _loadMockAssetFileInfo(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockImageCacheManage extends MockCacheManage with ImageCacheManager {
  MockImageCacheManage() : super();

  @override
  Stream<FileResponse> getImageFile(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
    int? maxHeight,
    int? maxWidth,
  }) async* {
    debugPrint('Getting image file for URL: $url');
    try {
      debugPrint('Successfully loaded asset file');
      final bytes = await rootBundle
          .load('assets/images/2.0x/Android_TV_living_room.png')
          .then((value) => value.buffer.asUint8List());
      final file = _InMemoryFile(bytes);

      yield FileInfo(
        file,
        FileSource.Cache,
        DateTime.now().add(const Duration(days: 30)),
        url,
      );
    } catch (e) {
      debugPrint('Error in getImageFile: $e');
      rethrow;
    }
  }
}
