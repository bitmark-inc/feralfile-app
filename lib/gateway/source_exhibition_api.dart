//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'source_exhibition_api.g.dart';

const totalSeries = 25;

@RestApi(baseUrl: '')
abstract class SourceExhibitionAPI {
  factory SourceExhibitionAPI(Dio dio, {String baseUrl}) = _SourceExhibitionAPI;

  @GET('/source_exhibition/exhibition.json')
  Future<String> getSourceExhibition();

  @GET('/source_exhibition/series.json')
  Future<String> getSourceSeries();
}

extension SourceExhibitionAPIHelper on SourceExhibitionAPI {
  Future<Exhibition> getSourceExhibitionInfo() async {
    final value = await getSourceExhibition();
    return Exhibition.fromJson(jsonDecode(value));
  }

  Future<List<FFSeries>> getSourceExhibitionSeries() async {
    try {
      final value = await getSourceSeries();
      final List<FFSeries> series = (jsonDecode(value) as List<dynamic>?)
              ?.map((element) => FFSeries.fromJson(element))
              .toList() ??
          [];
      return series;
    } catch (e) {
      return [];
    }
  }
}
