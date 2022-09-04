import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

Future<String> getFileExtension(String url) async {
  final ext = p.extension(url);
  if (ext.isNotEmpty) {
    return ext;
  }
  final resp = await http.head(Uri.parse(url));
  final mimeType = resp.headers["content-type"] ?? "";
  return extensionFromMime(mimeType);
}
