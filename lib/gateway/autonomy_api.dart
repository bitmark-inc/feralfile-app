//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'autonomy_api.g.dart';

@RestApi(baseUrl: "")
abstract class AutonomyApi {
  factory AutonomyApi(Dio dio, {String baseUrl}) = _AutonomyApi;

  @POST("/apis/v1/me/link-addresses")
  Future postLinkedAddressed(@Body() Map<String, List<String>> body);
}
