//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:dio/dio.dart';
import 'package:retrofit/http.dart';

part 'branch_api.g.dart';

@RestApi(baseUrl: "https://api2.branch.io")
abstract class BranchApi {
  factory BranchApi(Dio dio, {String baseUrl}) = _BranchApi;

  @GET("/v1/url")
  Future<dynamic> getParams(
    @Query("branch_key") String? key,
    @Query("url") String? url,
  );
}
