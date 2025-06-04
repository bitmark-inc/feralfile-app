import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:widgetbook_workspace/mock_data/data/series.dart';

class MockFFSeriesData {
  static FFSeries get evolvedFormulae01 =>
      FFSeries.fromJson(evolvedFormulaSeries01);

  static FFSeries get evolvedFormulae02 =>
      FFSeries.fromJson(evolvedFormulaSeries02);

  static FFSeries get evolvedFormulae03 =>
      FFSeries.fromJson(evolvedFormulaSeries03);

  static FFSeries get evolvedFormulae04 =>
      FFSeries.fromJson(evolvedFormulaSeries04);

  static List<FFSeries> get listSeries => [
        evolvedFormulae01,
        evolvedFormulae02,
        evolvedFormulae03,
        evolvedFormulae04,
      ];

  static List<FFSeries> getListSeriesByMedium(String medium) =>
      listSeries.where((s) => s.medium == medium).toList();

  static List<FFSeries> getListSeriesByArtist(String artistId) =>
      listSeries.where((s) => s.artistAlumniAccountID == artistId).toList();
}
