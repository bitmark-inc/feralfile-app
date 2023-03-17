import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/postcard_api.dart';

class PostcardService {
  final _postcardApi = injector.get<PostcardApi>();
  Future claimEmptyPostcard() async {
    final body = {"id": "postcard", "claimer": "tz1"};
    final response = await _postcardApi.claim(body);
    if (response.statusCode == 200) {
      final postcard = json.decode(response.body);
      return postcard;
    } else {
      throw Exception('Failed to load postcards');
    }
  }
}
