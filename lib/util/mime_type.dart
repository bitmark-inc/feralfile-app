import 'package:autonomy_flutter/util/log.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

class FileInfo {
  final String mimeType;
  final String extension;
  final int size;

  FileInfo(
    this.mimeType,
    this.extension,
    this.size,
  );
}

Future<FileInfo> getFileInfo(String url) async {
  try {
    final resp = await http
        .head(Uri.parse(url))
        .timeout(const Duration(milliseconds: 10000));
    final mimeType = resp.headers['content-type'] ?? '';
    final ext = extensionFromMime(mimeType) ?? '';
    final size = int.tryParse(resp.headers['content-length'] ?? '') ?? 0;
    return FileInfo(mimeType, ext, size);
  } catch (e) {
    log.info("Can't get file info $url. $e");
    return FileInfo('', '', 0);
  }
}
