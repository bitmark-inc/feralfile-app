//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/model/version_info.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'pubdoc_api.g.dart';

@RestApi(baseUrl: '')
abstract class PubdocAPI {
  factory PubdocAPI(Dio dio, {String baseUrl}) = _PubdocAPI;

  @GET('/versions.json')
  Future<String> getVersionContent();

  @GET('/release_notes/{app}/changelog.md')
  Future<String> getReleaseNotesContent(@Path('app') String app);

  @GET('/demo/demo_account.json')
  Future<String> getDemoAccount();

  @GET('/artists/suggested_artists.json')
  Future<String> getSuggestedArtists();

  @GET('/configs/postcard/postcard_configs.json')
  Future<String> getConfigs();
}

extension PubdocAPIHelpers on PubdocAPI {
  Future<VersionsInfo> getVersionsInfo() async {
    final value = await getVersionContent();
    return VersionsInfo.fromJson(jsonDecode(value));
  }

  Future<List<PlayListModel>> getDemoAccountFromGithub() async {
    final value = await getDemoAccount();
    final list = (jsonDecode(value) as List?)
        ?.map((element) => PlayListModel.fromJson(element))
        .toList();
    return list ?? [];
  }
}
