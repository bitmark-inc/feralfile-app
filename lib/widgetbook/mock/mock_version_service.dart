import 'package:autonomy_flutter/service/versions_service.dart';

class MockVersionService implements VersionService {
  @override
  Future<void> checkForUpdate() async {
    return Future.value();
  }

  @override
  Future<void> openLatestVersion() {
    return Future.value();
  }

  @override
  Future<void> showReleaseNotes({String? currentVersion}) {
    return Future.value();
  }
}
