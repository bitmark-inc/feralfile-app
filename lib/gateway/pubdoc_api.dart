import 'dart:convert';

import 'package:autonomy_flutter/model/version_info.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'pubdoc_api.g.dart';

@RestApi(
    baseUrl:
        "https://raw.githubusercontent.com/thuyenBitmark/temp-release-notes/master")
abstract class PubdocAPI {
  factory PubdocAPI(Dio dio, {String baseUrl}) = _PubdocAPI;

  @GET("/versions.json")
  Future<String> getVersionContent();
}

extension PubdocAPIHelpers on PubdocAPI {
  Future<VersionsInfo> getVersionsInfo() async {
    final value = await getVersionContent();
    return VersionsInfo.fromJson(jsonDecode(value));
  }
}
