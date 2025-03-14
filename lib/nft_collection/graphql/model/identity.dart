import 'package:autonomy_flutter/nft_collection/models/identity.dart';

class QueryIdentityResponse {
  QueryIdentityResponse({
    required this.identity,
  });

  factory QueryIdentityResponse.fromJson(Map<String, dynamic> map) {
    return QueryIdentityResponse(
      identity: map['identity'] != null
          ? Identity.fromJson(Map<String, dynamic>.from(map['identity'] as Map))
          : Identity('', '', ''),
    );
  }

  Identity identity;
}

class QueryIdentityRequest {
  QueryIdentityRequest({
    required this.account,
  });

  final String account;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'account': account,
    };
  }
}
