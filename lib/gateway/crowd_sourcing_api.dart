//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//
import 'package:autonomy_flutter/model/token_feedback.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'crowd_sourcing_api.g.dart';

@RestApi(baseUrl: "")
abstract class CrowdSourcingApi {
  factory CrowdSourcingApi(Dio dio, {String baseUrl}) = _CrowdSourcingApi;

  @GET("/v1/nft/help")
  Future<TokenFeedbackResponse> getTokenFeedbacks();

  @POST("/v1/nft/help/feedback")
  Future sendTokenFeedback(@Body() Map<String, dynamic> feedback);
}
