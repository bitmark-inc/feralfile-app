//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'rendering_report_api.g.dart';

@RestApi(baseUrl: "")
abstract class RenderingReportApi {
  factory RenderingReportApi(Dio dio, {String baseUrl}) = _RenderingReportApi;

  @POST("/v1/reports/")
  Future<Map<String, String>> report(
    @Body() Map<String, String?> body,
  );
}
