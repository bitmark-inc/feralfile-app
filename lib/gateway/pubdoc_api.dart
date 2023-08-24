//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/model/suggested_artist.dart';
import 'package:autonomy_flutter/model/version_info.dart';
import 'package:autonomy_flutter/screen/customer_support/tutorial_videos_page.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'pubdoc_api.g.dart';

@RestApi(baseUrl: "")
abstract class PubdocAPI {
  factory PubdocAPI(Dio dio, {String baseUrl}) = _PubdocAPI;

  @GET("/versions.json")
  Future<String> getVersionContent();

  @GET("/release_notes/{app}/changelog.md")
  Future<String> getReleaseNotesContent(@Path("app") String app);

  @GET("/demo/demo_account.json")
  Future<String> getDemoAccount();

  @GET("/tutorial_videos/tutorial_videos.json")
  Future<String> getTutorialVideos();

  @GET("/artists/suggested_artists.json")
  Future<String> getSuggestedArtists();
}

extension PubdocAPIHelpers on PubdocAPI {
  Future<VersionsInfo> getVersionsInfo() async {
    final value = await getVersionContent();
    return VersionsInfo.fromJson(jsonDecode(value));
  }

  Future<List<PlayListModel>> getDemoAccountFromGithub() async {
    final value = await getDemoAccount();
    final list = (jsonDecode(value) as List?)?.map((element) {
      return PlayListModel.fromJson(element);
    }).toList();
    return list ?? [];
  }

  Future<List<VideoData>> getTutorialVideosFromGithub() async {
    final value = await getTutorialVideos();
    final list = (jsonDecode(value) as List?)?.map((element) {
      return VideoData.fromJson(element);
    }).toList();
    return list ?? [];
  }

  Future<List<SuggestedArtist>> getSuggestedArtistsFromGithub() async {
    final value = await getSuggestedArtists();
    final list = (jsonDecode(value) as List<dynamic>?)?.map((element) {
      return SuggestedArtist.fromJson(element);
    }).toList();
    return list ?? [];
  }
}
