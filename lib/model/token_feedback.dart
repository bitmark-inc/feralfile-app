//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//
import 'package:json_annotation/json_annotation.dart';

part 'token_feedback.g.dart';

@JsonSerializable()
class TokenFeedbackResponse {
  TokenFeedbackResponse({
    required this.tokens,
    required this.requestID,
  });

  List<TokenFeedback> tokens;
  String requestID;

  factory TokenFeedbackResponse.fromJson(Map<String, dynamic> json) =>
      _$TokenFeedbackResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TokenFeedbackResponseToJson(this);
}

@JsonSerializable()
class TokenFeedback {
  TokenFeedback({
    required this.indexID,
    required this.previewURL,
  });

  String indexID;
  String previewURL;

  factory TokenFeedback.fromJson(Map<String, dynamic> json) =>
      _$TokenFeedbackFromJson(json);

  Map<String, dynamic> toJson() => _$TokenFeedbackToJson(this);
}
