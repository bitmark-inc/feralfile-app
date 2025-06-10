//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'source_exhibition_api.g.dart';

@RestApi(baseUrl: '')
abstract class SourceExhibitionAPI {
  factory SourceExhibitionAPI(Dio dio, {String baseUrl}) = _SourceExhibitionAPI;

  @GET('/app/source_exhibition/exhibition.json')
  Future<String> getSourceExhibition();

  @GET('/app/source_exhibition/series.json')
  Future<String> getSourceSeries();
}

extension SourceExhibitionAPIHelper on SourceExhibitionAPI {
  Future<Exhibition> getSourceExhibitionInfo() async {
    final value = await getSourceExhibition();
    return Exhibition.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  Future<List<FFSeries>> getSourceExhibitionSeries() async {
    try {
      final value = await getSourceSeries();
      final List<FFSeries> series = (jsonDecode(value) as List<dynamic>?)
              ?.map((element) =>
                  FFSeries.fromJson(element as Map<String, dynamic>))
              .toList() ??
          [];
      return series.map((e) => e.copyWith(artwork: e.artworks!.first)).toList();
    } catch (e) {
      log.info('Error fetching source exhibition series: $e');
      return [];
    }
  }
}
