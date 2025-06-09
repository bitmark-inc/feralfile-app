import 'dart:async';

import 'package:autonomy_flutter/util/au_file_service.dart';
import 'package:autonomy_flutter/util/feralfile_alumni_ext.dart';
import 'package:autonomy_flutter/widgetbook/mock/mock_injector.dart';
import 'package:autonomy_flutter/widgetbook/mock_data/mock_alumni.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file/file.dart' as file;
import 'package:file/local.dart' as localFile;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/file.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  // Initialize Golden Toolkit and load fonts
  setUpAll(() async {
    await loadAppFonts();

    MockInjector.setup();
    await EasyLocalization.ensureInitialized();
  });

  // group("Exhibition", () {
  //   testGoldens("Exhibition Card", (WidgetTester tester) async {
  //     final builder = GoldenBuilder.column()
  //       ..addScenario(
  //         "Exhibition Card",
  //         MockLocalization.wrapWithLocalization(
  //           child: Container(
  //             height: 300,
  //             width: 200,
  //             child: ExhibitionCard(
  //               exhibition: MockExhibitionData.evolvedFormulaeExhibition,
  //               viewableExhibitions: MockExhibitionData.listExhibition,
  //               width: 200,
  //               height: 300,
  //             ),
  //           ),
  //         ),
  //       );
  //     await tester.pumpWidgetBuilder(
  //       builder.build(),
  //       wrapper: materialAppWrapper(),
  //     );
  //
  //     await screenMatchesGolden(tester, "exhibition_card");
  //   });
  // });

  group('Golden - AlumniCard', () {
    setUpAll(() async {
      await loadAppFonts();
    });

    testGoldens('renders correctly', (WidgetTester tester) async {
      print('Starting test...');
      final builder = GoldenBuilder.column(
        bgColor: Colors.amber,
      )..addScenario(
          'Alumni Card',
          CachedNetworkImage(
            imageUrl: MockAlumniData.driessensVerstappen.avatarUrl!,
            width: 200,
            height: 200,
            cacheManager: MockCacheManage(),
          ));
      print('Pumping widget...');
      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
      );
      print('Pumping additional times...');
      await tester.pump(const Duration(milliseconds: 100));
      print('Taking golden screenshot...');

      await expectLater(
        find.byType(CachedNetworkImage),
        matchesGoldenFile('alumni_card.png'),
      );
      //
      // await screenMatchesGolden(tester, 'alumni_card',
      //     customPump: (tester) async {
      //   // Additional pump if needed for animations or transitions
      //   await tester.pump(const Duration(milliseconds: 100));
      // }, autoHeight: true);
      print('Test completed');
    });
  });

  group('Alumni', () {
    // testGoldens('Alumni Avatar', (WidgetTester tester) async {
    //   final builder = GoldenBuilder.column(
    //     bgColor: Colors.amber,
    //   )..addScenario(
    //       'Alumni Card',
    //       CachedNetworkImage(
    //         imageUrl: MockAlumniData.driessensVerstappen.avatarUrl!,
    //         width: 102,
    //         height: 102,
    //       ));
    //   await tester.pumpWidgetBuilder(
    //     builder.build(),
    //     wrapper: materialAppWrapper(),
    //   );
    //
    //   await screenMatchesGolden(tester, 'alumni_card',
    //       customPump: (tester) async {
    //     // Additional pump if needed for animations or transitions
    //     await tester.pump(const Duration(milliseconds: 100));
    //   }, autoHeight: true);
    // });
    // testGoldens('Alumni Card', (WidgetTester tester) async {
    //   final builder = GoldenBuilder.column(
    //       bgColor: Colors.amber,
    //       wrap: (child) {
    //         return MockLocalization.wrapWithLocalization(
    //             child: AspectRatio(
    //           aspectRatio: 102.0 / 152,
    //           child: Container(
    //             color: Colors.amberAccent,
    //             width: 102,
    //             height: 152,
    //             child: child,
    //           ),
    //         ));
    //       })
    //     ..addScenario(
    //         'Alumni Card',
    //         AlumniCard(
    //           alumni: MockAlumniData.driessensVerstappen,
    //         ));
    //   await tester.pumpWidgetBuilder(
    //     builder.build(),
    //     wrapper: materialAppWrapper(),
    //   );
    //
    //   await screenMatchesGolden(tester, 'alumni_card');
    // });
  });
}

class MockCacheManage implements BaseCacheManager {
  MockCacheManage();

  // : super(
  //     Config(
  //       "GoldenTest",
  //       fileService: AuFileService(),
  //       fileSystem: MockIOFileSystem("GoldenTest"),
  //       stalePeriod: const Duration(days: 30),
  //       maxNrOfCacheObjects: 10000,
  //     ),
  //   );

  @override
  Future<void> dispose() {
    // TODO: implement dispose
    throw UnimplementedError();
  }

  @override
  Future<FileInfo> downloadFile(String url,
      {String? key, Map<String, String>? authHeaders, bool force = false}) {
    // TODO: implement downloadFile
    throw UnimplementedError();
  }

  @override
  Future<void> emptyCache() {
    // TODO: implement emptyCache
    throw UnimplementedError();
  }

  @override
  Future<FileInfo?> getFileFromCache(String key,
      {bool ignoreMemCache = false}) {
    // TODO: implement getFileFromCache
    throw UnimplementedError();
  }

  @override
  Future<FileInfo?> getFileFromMemory(String key) {
    // TODO: implement getFileFromMemory
    throw UnimplementedError();
  }

  @override
  Stream<FileResponse> getFileStream(String url,
      {String? key, Map<String, String>? headers, bool? withProgress}) {
    final localFileSystem = localFile.LocalFileSystem();
    final localF =
        localFileSystem.file('assets/images/2.0x/Android_TV_living_room.png');
    final fileInfo = FileInfo(
      localF,
      FileSource.Cache,
      DateTime.now().add(const Duration(days: 30)),
      url,
    );
    return Stream<FileResponse>.value(fileInfo);
  }

  @override
  Future<file.File> getSingleFile(String url,
      {String? key, Map<String, String>? headers}) {
    // TODO: implement getSingleFile
    throw UnimplementedError();
  }

  @override
  Future<file.File> putFile(String url, Uint8List fileBytes,
      {String? key,
      String? eTag,
      Duration maxAge = const Duration(days: 30),
      String fileExtension = 'file'}) {
    // TODO: implement putFile
    throw UnimplementedError();
  }

  @override
  Future<file.File> putFileStream(String url, Stream<List<int>> source,
      {String? key,
      String? eTag,
      Duration maxAge = const Duration(days: 30),
      String fileExtension = 'file'}) {
    // TODO: implement putFileStream
    throw UnimplementedError();
  }

  @override
  Future<void> removeFile(String key) {
    // TODO: implement removeFile
    throw UnimplementedError();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAUImageCacheManage extends MockCacheManage with ImageCacheManager {
  // constructor
  MockAUImageCacheManage();
}

class MockAuFileService extends FileService {
  // constructor
  MockAuFileService() : super();

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final filePath = 'assets/images/2.0x/Android_TV_living_room.png';
    final fileExt = 'svg';
    return AuFileServiceResponse(
      filePath: filePath,
      fileExt: fileExt,
    );
  }
}

class MockIOFileSystem implements FileSystem {
  MockIOFileSystem(this._cacheKey);

  final String _cacheKey;

  // createDirectory
  @override
  Future<File> createFile(String name) async {
    return LocalFile(name);
  }
}

// Mock File classes
class LocalFile implements File {
  LocalFile(this.path);

  final String path;

  // Implement other required methods...
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class LocalDirectory implements file.Directory {
  LocalDirectory(this.path);

  final String path;

  @override
  Future<file.Directory> create({bool recursive = false}) async => this;

  @override
  Future<bool> exists() async => true;

  // Implement other required methods...
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
