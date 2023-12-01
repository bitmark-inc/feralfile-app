// //
// //  SPDX-License-Identifier: BSD-2-Clause-Patent
// //  Copyright © 2022 Bitmark. All rights reserved.
// //  Use of this source code is governed by the BSD-2-Clause Plus Patent License
// //  that can be found in the LICENSE file.
// //
//
import 'package:autonomy_flutter/model/ether_gas.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/http.dart';

part 'etherchain_api.g.dart';

@RestApi(baseUrl: 'https://beaconcha.in')
abstract class EtherchainApi {
  factory EtherchainApi(Dio dio, {String baseUrl}) = _EtherchainApi;

  @GET('/api/v1/execution/gasnow')
  Future<EtherGas> getGasPrice();
}
