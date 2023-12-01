//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'tzkt_api.g.dart';

@RestApi(baseUrl: '')
abstract class TZKTApi {
  factory TZKTApi(Dio dio, {String baseUrl}) = _TZKTApi;

  @GET('/v1/accounts/{address}/operations')
  Future<List<TZKTOperation>> getOperations(
    @Path('address') String address, {
    @Query('type') String type = 'transaction',
    @Query('quote') String quote = 'usd',
    @Query('sort') int sort = 1,
    @Query('limit') int limit = 100,
    @Query('lastId') int? lastId,
    @Query('initiator.ne') String? initiator,
  });

  @GET('/v1/tokens/transfers')
  Future<List<TZKTTokenTransfer>> getTokenTransfer({
    @Query('anyof.from.to') String? anyOf,
    @Query('to') String? to,
    @Query('sort.desc') String sort = 'id',
    @Query('limit') int? limit,
    @Query('lastId') int? lastId,
    @Query('timestamp.gt') String? lastTime,
  });
}
