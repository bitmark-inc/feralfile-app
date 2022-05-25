//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/model/backup_versions.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'iap_api.g.dart';

@RestApi(baseUrl: "")
abstract class IAPApi {
  static const authenticationPath = "/apis/v1/auth";

  factory IAPApi(Dio dio, {String baseUrl}) = _IAPApi;

  @POST("/auth")
  Future<JWT> verifyIAP(@Body() Map<String, String> body);

  @POST(authenticationPath)
  Future<JWT> auth(@Body() Map<String, dynamic> body);

  @MultiPart()
  @POST("/apis/v1/premium/profile-data")
  Future<dynamic> uploadProfile(
    @Header("requester") String requester,
    @Part(name: "filename") String filename,
    @Part(name: "appVersion") String appVersion,
    @Part(name: "data") File data,
  );

  @GET("/apis/v1/premium/profile-data/versions")
  Future<BackupVersions> getProfileVersions(
    @Header("requester") String requester,
    @Query("filename") String filename,
  );

  @DELETE("/apis/v1/premium/profile-data")
  Future deleteAllProfiles(
    @Header("requester") String requester,
  );

  @POST("/apis/v1/me/identity-hash")
  Future<OnesignalIdentityHash> generateIdentityHash(
      @Body() Map<String, String> body);
}
