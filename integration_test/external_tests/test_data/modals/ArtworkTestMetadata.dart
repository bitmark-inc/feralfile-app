//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:http/http.dart' as http;

class ArtworkTestMetadata {
  final String balance;

  const ArtworkTestMetadata({
    required this.balance,
  });

  factory ArtworkTestMetadata.fromJson(Map<String, dynamic> json) {
    return ArtworkTestMetadata(
      balance: json['balance'],
    );
  }
}

Future<ArtworkTestMetadata> fetchArtwork(String URL) async {
  final response = await http.get(Uri.parse(URL));

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.

    final data = jsonDecode(response.body) as List<dynamic>;
    return ArtworkTestMetadata.fromJson(data.first);
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load ArtworkTestMetadata');
  }
}
