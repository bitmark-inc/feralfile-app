import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_series/feralfile_series_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:http/http.dart' as http;

class FeralFileSeriesBloc
    extends AuBloc<FeralFileSeriesEvent, FeralFileSeriesState> {
  final FeralFileService _feralFileService;

  FeralFileSeriesBloc(this._feralFileService) : super(FeralFileSeriesState()) {
    on<FeralFileSeriesGetSeriesEvent>((event, emit) async {
      final series = await _feralFileService.getSeries(event.seriesId,
          exhibitionID: event.exhibitionId, includeFirstArtwork: true);
      final thumbnailUrl = series.artwork?.thumbnailURL;
      double thumbnailRatio = 1;
      if (thumbnailUrl != null) {
        thumbnailRatio = await _getImageRatio(thumbnailUrl);
      }
      emit(state.copyWith(
        series: series,
        thumbnailRatio: thumbnailRatio,
      ));
    });
  }

  Future<double> _getImageRatio(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;

      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(Uint8List.fromList(bytes), (image) {
        completer.complete(image);
      });

      final image = await completer.future;
      return image.width / image.height;
    } catch (e) {
      return 1;
    }
  }
}
