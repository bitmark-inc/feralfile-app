//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/model/announcement/announcement.dart';
import 'package:autonomy_flutter/model/announcement/announcement_request.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/model/ok_response.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'iap_api.g.dart';

@RestApi(baseUrl: '')
abstract class IAPApi {
  static const addressAuthenticationPath = '/apis/v2/addresses/auth';
  static const registerPrimaryAddressPath = '/apis/v2/addresses/primary';

  factory IAPApi(Dio dio, {String baseUrl}) = _IAPApi;

  @POST(addressAuthenticationPath)
  Future<JWT> authAddress(@Body() Map<String, dynamic> body);

  @POST(registerPrimaryAddressPath)
  Future<void> registerPrimaryAddress(@Body() Map<String, dynamic> body);

  @MultiPart()
  @POST('/apis/v1/premium/profile-data')
  Future<dynamic> uploadProfile(
    @Header('requester') String requester,
    @Part(name: 'filename') String filename,
    @Part(name: 'appVersion') String appVersion,
    @Part(name: 'data') File data,
  );

  @GET('/apis/v1/premium/profile-data')
  Future<dynamic> getProfileData(
    @Header('requester') String requester,
    @Query('filename') String filename,
    @Query('appVersion') String version,
  );

  @DELETE('/apis/v1/premium/profile-data')
  Future deleteAllProfiles(
    @Header('requester') String requester,
  );

  @DELETE('/apis/v1/me')
  Future deleteUserData();

  @POST('/apis/v1/me/identity-hash')
  Future<OnesignalIdentityHash> generateIdentityHash(
      @Body() Map<String, String> body);

  @GET('/apis/v2/announcements')
  Future<List<Announcement>> getAnnouncements(@Body() AnnouncementRequest body);

  @POST('/apis/v2/gift-code/{id}/redeem')
  Future<OkResponse> redeemGiftCode(
    @Path('id') String id,
  );

  @PATCH('/apis/metric-devices/{id}')
  Future<void> updateMetrics(
    @Path('id') String deviceId,
  );

  @POST('/apis/metrics')
  Future<void> sendEvent(
    @Body() Map<String, dynamic> metrics,
    @Header('x-device-id') String deviceId,
  );
}
