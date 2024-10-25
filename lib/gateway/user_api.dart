//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/credential_request_option.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/model/passkey_creation_option.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'user_api.g.dart';

@RestApi(baseUrl: '')
abstract class UserApi {
  factory UserApi(Dio dio, {String baseUrl}) = _UserApi;

  @POST('/apis/users/passkeys/registration/initialize')
  Future<CredentialCreationOption> registerInitialize();

  @POST('/apis/users/passkeys/registration/finalize')
  Future<JWT> registerFinalize(@Body() Map<String, dynamic> body);

  @POST('/apis/users/passkeys/login/initialize')
  Future<CredentialRequestOption> logInInitialize();

  @POST('/apis/users/passkeys/login/finalize')
  Future<JWT> logInFinalize(@Body() Map<String, dynamic> body);

  @POST('/apis/users/addresses/authenticate')
  Future<JWT> authenticateAddress(@Body() Map<String, dynamic> body);

  @POST('/apis/users/jwt/refresh')
  Future<JWT> refreshJWT(@Body() Map<String, dynamic> body);
}
