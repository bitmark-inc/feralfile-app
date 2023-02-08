// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenFeedbackResponse _$TokenFeedbackResponseFromJson(
        Map<String, dynamic> json) =>
    TokenFeedbackResponse(
      tokens: (json['tokens'] as List<dynamic>)
          .map((e) => TokenFeedback.fromJson(e as Map<String, dynamic>))
          .toList(),
      requestID: json['requestID'] as String,
    );

Map<String, dynamic> _$TokenFeedbackResponseToJson(
        TokenFeedbackResponse instance) =>
    <String, dynamic>{
      'tokens': instance.tokens,
      'requestID': instance.requestID,
    };

TokenFeedback _$TokenFeedbackFromJson(Map<String, dynamic> json) =>
    TokenFeedback(
      indexID: json['indexID'] as String,
      previewURL: json['previewURL'] as String,
    );

Map<String, dynamic> _$TokenFeedbackToJson(TokenFeedback instance) =>
    <String, dynamic>{
      'indexID': instance.indexID,
      'previewURL': instance.previewURL,
    };
