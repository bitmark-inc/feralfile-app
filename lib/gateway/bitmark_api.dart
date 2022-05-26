//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/bitmark.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'bitmark_api.g.dart';

@RestApi(baseUrl: "")
abstract class BitmarkApi {
  factory BitmarkApi(Dio dio, {String baseUrl}) = _BitmarkApi;

  @GET("/v1/bitmarks")
  Future<Map<String, List<Bitmark>>> getBitmarkIDs(
    @Query("owner") String owner,
    @Query("pending") bool includePending,
  );
}
